import UIKit

struct DetectionResult {
    var faces: [CGRect] = []
    var emails: [CGRect] = []
    var phones: [CGRect] = []
    var amounts: [CGRect] = []
    var ids: [CGRect] = []
    var barcodes: [CGRect] = []
    
    func allBoxes(dilate: CGFloat) -> [CGRect] {
        var r: [CGRect] = []
        r += faces + emails + phones + amounts + ids + barcodes
        return dilate > 0 ? r.map { $0.insetBy(dx: -dilate, dy: -dilate) } : r
    }
}

struct RedactionStats {
    let emails: Int, phones: Int, amounts: Int, ids: Int, faces: Int, barcodes: Int
    var total: Int { emails + phones + amounts + ids + faces + barcodes }
    var description: String {
        var parts:[String]=[]
        if emails>0 { parts.append("\(emails) emails") }
        if phones>0 { parts.append("\(phones) phones") }
        if amounts>0 { parts.append("\(amounts) amounts") }
        if ids>0 { parts.append("\(ids) IDs") }
        if faces>0 { parts.append("\(faces) faces") }
        if barcodes>0 { parts.append("\(barcodes) codes") }
        return parts.joined(separator: ", ")
    }
    init(from det: DetectionResult, leaks: VerifyResult) {
        emails=det.emails.count; phones=det.phones.count; amounts=det.amounts.count; ids=det.ids.count; faces=det.faces.count; barcodes=det.barcodes.count
    }
}

struct RedactionResult: Identifiable {
    let id = UUID()
    let original: UIImage
    let preview: UIImage
    let finalImage: UIImage
    let stats: RedactionStats
}
