import SwiftUI

struct ExportView: View {
    let results: [RedactionResult]
    @Environment(\.dismiss) var dismiss
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(results) { r in
                        HStack {
                            Image(uiImage: r.finalImage).resizable().aspectRatio(contentMode: .fit).frame(height: 120).cornerRadius(8)
                            VStack(alignment: .leading) {
                                Text("Redacted: \(r.stats.total) items")
                                Text(r.stats.description).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                HStack {
                    Button("Close") { dismiss() }.buttonStyle(.bordered)
                    Spacer()
                    Button(isSaving ? "Saving..." : "Save to Photos") { Task { await saveAll() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaving)
                }.padding()
            }.navigationTitle("Export")
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    func saveAll() async {
        isSaving = true
        let manager = PhotoLibraryManager()
        
        do {
            try await manager.save(images: results.map{ $0.finalImage }, albumName: "ShareClean")
        } catch PhotoLibraryError.unauthorized {
            errorMessage = "Photo library access denied. Please enable access in Settings."
            showError = true
        } catch PhotoLibraryError.albumCreationFailed {
            errorMessage = "Failed to create ShareClean album. Please try again."
            showError = true
        } catch PhotoLibraryError.saveFailed(let error) {
            errorMessage = "Failed to save images: \(error.localizedDescription)"
            showError = true
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
            showError = true
        }
        
        isSaving = false
    }
}
