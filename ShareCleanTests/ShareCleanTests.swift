import XCTest
@testable import ShareClean
import Vision
import CoreImage

final class ShareCleanTests: XCTestCase {
    func renderTextImage(_ text: String, size: CGSize = CGSize(width: 1200, height: 800)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        UIColor.white.setFill(); UIRectFill(CGRect(origin: .zero, size: size))
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 48), .foregroundColor: UIColor.black]
        NSString(string: text).draw(in: CGRect(x: 40, y: 200, width: size.width-80, height: size.height-240), withAttributes: attrs)
        let out = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext(); return out
    }
    func renderQRCode(_ string: String, size: CGFloat = 400) -> UIImage {
        let data = string.data(using: .utf8)!
        let filter = CIFilter(name: "CIQRCodeGenerator")!
        filter.setValue(data, forKey: "inputMessage"); filter.setValue("M", forKey: "inputCorrectionLevel")
        let img = filter.outputImage!
        let scaled = img.transformed(by: CGAffineTransform(scaleX: size/img.extent.width, y: size/img.extent.height))
        let ctx = CIContext(); let cg = ctx.createCGImage(scaled, from: scaled.extent)!
        return UIImage(cgImage: cg)
    }
    func test_SnapshotVerify_NoLeaks_EmailPhone() throws {
        let base = renderTextImage("Email: a.b@example.com  Phone: +44 20 7123 4567  Amount: €1,234.56  Code: ZX1Y2Z")
        var settings = DetectionSettings.default; settings.detectBarcodes = false
        let det = VisionDetector(settings: settings).detect(in: base)
        let red = RedactionRenderer().applyMasks(on: base, boxes: det.allBoxes(dilate: settings.dilation))
        let verify = VerifyService(settings: settings).verify(image: red, targeted: [.email,.phone,.amount,.idcode])
        XCTAssertFalse(verify.hasLeaks, "Snapshot expectation: 0 leaks after redaction")
    }
    func test_SnapshotVerify_QR() throws {
        let qr = renderQRCode("SENSITIVE:ABC123")
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1200, height: 800), true, 1.0)
        UIColor.white.setFill(); UIRectFill(CGRect(x: 0, y: 0, width: 1200, height: 800))
        qr.draw(in: CGRect(x: 350, y: 200, width: 500, height: 500))
        let img = UIGraphicsGetImageFromCurrentImageContext()!; UIGraphicsEndImageContext()
        var settings = DetectionSettings.default; settings.detectEmails=false; settings.detectPhones=false; settings.detectAmounts=false; settings.detectIDs=true; settings.detectBarcodes=true
        let det = VisionDetector(settings: settings).detect(in: img)
        XCTAssertGreaterThan(det.barcodes.count, 0, "Expected a barcode detected")
        let red = RedactionRenderer().applyMasks(on: img, boxes: det.allBoxes(dilate: settings.dilation))
        let verify = VerifyService(settings: settings).verify(image: red, targeted: [.idcode])
        XCTAssertFalse(verify.hasLeaks, "Snapshot expectation: 0 leaks after redaction")
    }
}
