import UIKit
import UniformTypeIdentifiers
import Vision

final class ActionViewController: UIViewController {
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var faces: UISwitch!
    @IBOutlet weak var emails: UISwitch!
    @IBOutlet weak var phones: UISwitch!
    @IBOutlet weak var amounts: UISwitch!
    @IBOutlet weak var ids: UISwitch!
    @IBOutlet weak var codes: UISwitch!
    @IBOutlet weak var btn: UIButton!
    
    var inputImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        faces.isOn = true; emails.isOn = true; phones.isOn = true; amounts.isOn = true; ids.isOn = true; codes.isOn = true
        fetchInput()
    }
    private func fetchInput() {
        guard let item = self.extensionContext?.inputItems.first as? NSExtensionItem else { 
            print("No input items available")
            return 
        }
        guard let provider = item.attachments?.first else { 
            print("No attachments available")
            return 
        }
        let type = UTType.image.identifier
        provider.loadItem(forTypeIdentifier: type, options: nil) { (data, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }
                
                if let url = data as? URL {
                    do {
                        let d = try Data(contentsOf: url)
                        if let ui = UIImage(data: d) {
                            self.inputImage = ui
                            self.img.image = ui
                        }
                    } catch {
                        print("Error reading image from URL: \(error)")
                    }
                } else if let d = data as? Data, let ui = UIImage(data: d) {
                    self.inputImage = ui
                    self.img.image = ui
                } else {
                    print("Unable to load image from provided data")
                }
            }
        }
    }
    @IBAction func doRedact(_ sender: Any) {
        guard let ui = inputImage else { return }
        let isPro = AppConstants.defaults().bool(forKey: "isPro")
        if !QuotaManager.shared.canAutoRedact(isPro: isPro) {
            let alert = UIAlertController(title: "Limit reached", message: "Free limit reached. Open ShareClean to go Pro for unlimited auto-redaction.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true); return
        }
        var settings = DetectionSettings.default
        settings.detectFaces = faces.isOn
        settings.detectEmails = emails.isOn
        settings.detectPhones = phones.isOn
        settings.detectAmounts = amounts.isOn
        settings.detectIDs = ids.isOn
        settings.detectBarcodes = codes.isOn
        
        let det = VisionDetector(settings: settings).detect(in: ui)
        let out = RedactionRenderer().applyMasks(on: ui, boxes: det.allBoxes(dilate: settings.dilation))
        guard let jpeg = out.jpegData(compressionQuality: 0.9) else { 
            print("Failed to create JPEG data")
            return 
        }
        let item = NSExtensionItem()
        let provider = NSItemProvider(item: jpeg as NSSecureCoding, typeIdentifier: UTType.jpeg.identifier)
        item.attachments = [provider]
        QuotaManager.shared.incrementAutoRedacts()
        self.extensionContext?.completeRequest(returningItems: [item], completionHandler: nil)
    }
}
