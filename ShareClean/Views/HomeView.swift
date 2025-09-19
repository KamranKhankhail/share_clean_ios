import SwiftUI
import PhotosUI

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var images: [ImageModel] = []
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showExport = false
    @State private var results: [RedactionResult] = []
    @State private var navigateToDetect = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                Text("One‑Tap PII Redaction (Offline)").font(.headline)
                Text("Faces • Emails • Phones • Amounts • IDs • QR • EXIF").font(.footnote).foregroundStyle(.secondary)
                
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                    Text("Import up to 5 images").frame(maxWidth: .infinity).padding().background(Color.blue).foregroundColor(.white).cornerRadius(12)
                }.onChange(of: selectedItems) { _ in Task { await loadSelected() } }
                
                if !images.isEmpty {
                    Button {
                        navigateToDetect = true
                    } label: {
                        Text("Detect & Redact")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }

                Button("Settings") { showSettings = true }.buttonStyle(.bordered)
                if !app.isPro { Button("Go Pro") { showPaywall = true }.buttonStyle(.borderedProminent) }
                Spacer()
            }
            .padding()
            .navigationTitle("ShareClean")
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showExport) { ExportView(results: results) }
        }
        .navigationDestination(isPresented: $navigateToDetect) {
            DetectView(images: images) { r in
                results = r
                showExport = true
            }
        }
    }
    
    func loadSelected() async {
        await MainActor.run {
            navigateToDetect = false
            images.removeAll()
        }
        for item in selectedItems.prefix(5) {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) { 
                    await MainActor.run {
                        images.append(ImageModel(uiImage: ui))
                    }
                }
            } catch {
                print("Failed to load image: \(error)")
            }
        }
        await MainActor.run {
            navigateToDetect = !images.isEmpty
        }
    }
}
