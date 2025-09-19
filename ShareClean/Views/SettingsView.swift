import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Auto-detect types")) {
                    Toggle("Faces", isOn: $app.settings.detectFaces)
                    Toggle("Emails", isOn: $app.settings.detectEmails)
                    Toggle("Phones", isOn: $app.settings.detectPhones)
                    Toggle("Amounts", isOn: $app.settings.detectAmounts)
                    Toggle("IDs & Codes", isOn: $app.settings.detectIDs)
                    Toggle("QR & Barcodes", isOn: $app.settings.detectBarcodes)
                }
                Section(header: Text("Masking")) {
                    Stepper("Mask dilation: \(Int(app.settings.dilation)) px", value: $app.settings.dilation, in: 0...8, step: 1)
                }
                Section(header: Text("General")) {
                    Toggle("Strip EXIF always", isOn: $app.settings.stripEXIF)
                }
            }.navigationTitle("Settings")
        }
    }
}
