import SwiftUI
import Vision

struct DetectView: View {
    let images: [ImageModel]
    var onResults: ([RedactionResult]) -> Void
    
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var working = false
    @State private var progress: Double = 0
    @State private var results: [RedactionResult] = []
    
    var body: some View {
        VStack {
            if working {
                ProgressView(value: progress).padding()
                Text("Processing...").font(.footnote)
            } else {
                List {
                    ForEach(results) { res in
                        HStack {
                            Image(uiImage: res.preview).resizable().aspectRatio(contentMode: .fit).frame(width: 80, height: 80).cornerRadius(8)
                            VStack(alignment: .leading) {
                                Text("Redacted: \(res.stats.total) items").font(.subheadline)
                                Text("\(res.stats.description)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            HStack {
                Button("Cancel") { dismiss() }.buttonStyle(.bordered)
                Spacer()
                Button("Run") { Task { await run() } }.buttonStyle(.borderedProminent)
            }.padding()
        }
        .onAppear { if results.isEmpty { Task { await run(previewOnly: true) } } }
        .navigationTitle("Detect & Redact")
    }
    
    func run(previewOnly: Bool = false) async {
        let canAuto = QuotaManager.shared.canAutoRedact(isPro: app.isPro)
        if !canAuto && !previewOnly { return }
        working = true; results.removeAll()
        let total = Double(images.count); var i = 0.0
        
        for img in images {
            autoreleasepool {
                let det = VisionDetector(settings: app.settings).detect(in: img.uiImage)
                let red = RedactionRenderer().applyMasks(on: img.uiImage, boxes: det.allBoxes(dilate: app.settings.dilation))
                let verify = VerifyService(settings: app.settings).verify(image: red, targeted: [.email,.phone,.amount,.idcode,.barcode,.face])
                let final = verify.hasLeaks ? RedactionRenderer().applyMasks(on: red, boxes: verify.leakBoxes.map{ $0.insetBy(dx: -4, dy: -4) }) : red
                let stripped = EXIFStripper.strip(final)
                let stats = RedactionStats(from: det, leaks: verify)
                results.append(RedactionResult(original: img.uiImage, preview: stripped, finalImage: stripped, stats: stats))
            }
            i += 1; progress = i/total
        }
        working = false
        if !previewOnly { QuotaManager.shared.incrementAutoRedacts(); onResults(results) }
    }
}
