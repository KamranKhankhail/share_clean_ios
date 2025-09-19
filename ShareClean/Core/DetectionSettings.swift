import Foundation
import CoreGraphics

struct DetectionSettings: Codable {
    var detectFaces: Bool
    var detectEmails: Bool
    var detectPhones: Bool
    var detectAmounts: Bool
    var detectIDs: Bool
    var detectBarcodes: Bool
    var dilation: CGFloat
    var stripEXIF: Bool
    static var `default`: DetectionSettings {
        DetectionSettings(detectFaces: true, detectEmails: true, detectPhones: true, detectAmounts: true, detectIDs: true, detectBarcodes: true, dilation: 3, stripEXIF: true)
    }
}
enum PIIType: String, CaseIterable { case face, email, phone, amount, idcode, barcode }
