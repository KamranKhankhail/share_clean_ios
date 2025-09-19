import SwiftUI

struct ExportView: View {
    let results: [RedactionResult]
    @Environment(\.dismiss) var dismiss
    @State private var isSaving = false
    
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
        }
    }
    
    func saveAll() async {
        isSaving = true
        let manager = PhotoLibraryManager()
        await manager.save(images: results.map{ $0.finalImage }, albumName: "ShareClean")
        isSaving = false
    }
}
