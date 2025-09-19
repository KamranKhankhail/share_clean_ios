import SwiftUI
import Vision

struct DetectView: View {
    let images: [ImageModel]
    var onResults: ([RedactionResult]) -> Void
    
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var working = false
    @State private var progress: Double = 0
    @State private var statusMessage: String = ""
    @State private var results: [RedactionResult] = []
    @State private var quotaAlertMessage: String?
    @State private var hasProcessedOnce = false
    
    var body: some View {
        ZStack {
            VStack {
                if results.isEmpty && !working {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("Results will appear here once processing finishes.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(results) { res in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(uiImage: res.preview)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 96, height: 96)
                                        .clipped()
                                        .cornerRadius(12)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Redacted: \(res.stats.total) items")
                                            .font(.headline)
                                        Text(res.stats.description.isEmpty ? "No sensitive data found." : res.stats.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if res.stats.hasLeaks {
                                            Text("Follow-up masks applied to \(res.stats.leakCount) potential leaks.")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding()
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(16)
                            }
                        }
                        .padding()
                    }
                }
                HStack {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.bordered)
                    Spacer()
                    Button("Run") { Task { await run() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(working)
                }
                .padding()
            }
            if working {
                VStack(spacing: 12) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                    Text(statusMessage)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: 260)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Detect & Redact")
        .task { await startIfNeeded() }
        .alert("Processing unavailable", isPresented: Binding(get: { quotaAlertMessage != nil }, set: { if !$0 { quotaAlertMessage = nil } })) {
            Button("OK", role: .cancel) { quotaAlertMessage = nil }
        } message: {
            Text(quotaAlertMessage ?? "")
        }
    }
    
    func startIfNeeded() async {
        if !hasProcessedOnce {
            await run()
        }
    }
    
    func run() async {
        let canAuto = QuotaManager.shared.canAutoRedact(isPro: app.isPro)
        guard canAuto else {
            await MainActor.run {
                quotaAlertMessage = "Daily auto-redaction limit reached. Upgrade to Pro for unlimited processing."
            }
            return
        }

        await MainActor.run {
            working = true
            progress = 0
            statusMessage = "Starting…"
            results.removeAll()
        }

        let totalCount = images.count
        let settings = app.settings

        var collected: [RedactionResult] = []
        for (index, img) in images.enumerated() {
            await MainActor.run {
                statusMessage = "Processing image \(index + 1) of \(totalCount)…"
                progress = Double(index) / Double(max(totalCount, 1))
            }

            let result = await Task.detached(priority: .userInitiated) { () -> RedactionResult in
                let detector = VisionDetector(settings: settings)
                let detection = detector.detect(in: img.uiImage)
                let redacted = RedactionRenderer().applyMasks(on: img.uiImage, boxes: detection.allBoxes(dilate: settings.dilation))
                let verify = VerifyService(settings: settings).verify(image: redacted, targeted: [.email,.phone,.amount,.idcode,.barcode,.face])
                let final = verify.hasLeaks ? RedactionRenderer().applyMasks(on: redacted, boxes: verify.leakBoxes.map { $0.insetBy(dx: -4, dy: -4) }) : redacted
                let stripped = settings.stripEXIF ? EXIFStripper.strip(final) : final
                let stats = RedactionStats(from: detection, leaks: verify)
                return RedactionResult(original: img.uiImage, preview: stripped, finalImage: stripped, stats: stats)
            }.value

            collected.append(result)
            await MainActor.run {
                results = collected
                progress = Double(index + 1) / Double(max(totalCount, 1))
            }
        }

        await MainActor.run {
            working = false
            statusMessage = "Completed"
            progress = 1
            hasProcessedOnce = true
        }
        QuotaManager.shared.incrementAutoRedacts()
        onResults(collected)
    }
}
