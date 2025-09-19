import UIKit
import Photos
import Vision

final class PhotoEditingViewController: UIViewController, PHContentEditingController {
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var faces: UISwitch!
    @IBOutlet weak var emails: UISwitch!
    @IBOutlet weak var phones: UISwitch!
    @IBOutlet weak var amounts: UISwitch!
    @IBOutlet weak var ids: UISwitch!
    @IBOutlet weak var codes: UISwitch!
    @IBOutlet weak var apply: UIButton!
    
    var input: PHContentEditingInput?
    
    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        return adjustmentData.formatIdentifier == "com.shareclean.adjust" && adjustmentData.formatVersion == "1.0"
    }
    func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: UIImage) {
        self.input = contentEditingInput; self.img.image = placeholderImage
        faces.isOn = true; emails.isOn = true; phones.isOn = true; amounts.isOn = true; ids.isOn = true; codes.isOn = true
    }
    func finishContentEditing(completionHandler: @escaping (PHContentEditingOutput?) -> Void) {
        guard let input = input else { completionHandler(nil); return }
        let isPro = AppConstants.defaults().bool(forKey: "isPro")
        if !QuotaManager.shared.canAutoRedact(isPro: isPro) { completionHandler(nil); return }
        
        let output = PHContentEditingOutput(contentEditingInput: input)
        let url = input.fullSizeImageURL ?? input.renderedContentURL
        guard let srcURL = url, let data = try? Data(contentsOf: srcURL), let ui = UIImage(data: data) else { completionHandler(nil); return }
        var settings = DetectionSettings.default
        settings.detectFaces = faces.isOn; settings.detectEmails = emails.isOn; settings.detectPhones = phones.isOn
        settings.detectAmounts = amounts.isOn; settings.detectIDs = ids.isOn; settings.detectBarcodes = codes.isOn
        
        let det = VisionDetector(settings: settings).detect(in: ui)
        let red = RedactionRenderer().applyMasks(on: ui, boxes: det.allBoxes(dilate: settings.dilation))
        let out = EXIFStripper.strip(red)
        if let jpeg = out.jpegData(compressionQuality: 0.9) { try? jpeg.write(to: output.renderedContentURL!) } else { completionHandler(nil); return }
        output.adjustmentData = PHAdjustmentData(formatIdentifier: "com.shareclean.adjust", formatVersion: "1.0", data: Data("redacted".utf8))
        QuotaManager.shared.incrementAutoRedacts()
        completionHandler(output)
    }
    func shouldShowCancelConfirmation() -> Bool { false }
}
