import UIKit
import Vision

final class VisionDetector {
    let settings: DetectionSettings
    init(settings: DetectionSettings) { self.settings = settings }
    func detect(in image: UIImage) -> DetectionResult {
        guard let cg = image.cgImage else { return DetectionResult() }
        let maxPixels: CGFloat = 3_000_000
        let scale = min(1.0, sqrt(maxPixels / CGFloat(cg.width * cg.height)))
        let detImage: CGImage
        if scale < 1.0 {
            let w = Int(CGFloat(cg.width) * scale), h = Int(CGFloat(cg.height) * scale)
            let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.interpolationQuality = .high; ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h)); detImage = ctx.makeImage()!
        } else { detImage = cg }
        var res = DetectionResult()
        let handler = VNImageRequestHandler(cgImage: detImage, options: [:])
        var reqs: [VNRequest] = []
        if settings.detectFaces {
            let faceRequest = VNDetectFaceRectanglesRequest { rq,_ in
                let boxes = (rq.results as? [VNFaceObservation])?.map {
                    $0.boundingBox.scaled(to: CGSize(width: detImage.width, height: detImage.height))
                } ?? []
                res.faces += boxes
            }
            faceRequest.revision = VNDetectFaceRectanglesRequestRevision3
            reqs.append(faceRequest)
        }
        if settings.detectBarcodes {
            let barcodeRequest = VNDetectBarcodesRequest { rq,_ in
                let boxes = (rq.results as? [VNBarcodeObservation])?.map {
                    $0.boundingBox.scaled(to: CGSize(width: detImage.width, height: detImage.height))
                } ?? []
                res.barcodes += boxes
            }
            barcodeRequest.revision = VNDetectBarcodesRequestRevision3
            barcodeRequest.symbologies = [.QR,.aztec,.pdf417,.dataMatrix,.EAN13,.UPCE,.code128]
            reqs.append(barcodeRequest)
        }
        let textReq = VNRecognizeTextRequest { rq,_ in
            guard self.settings.detectEmails || self.settings.detectPhones || self.settings.detectAmounts || self.settings.detectIDs else { return }
            let obs = (rq.results as? [VNRecognizedTextObservation]) ?? []
            for o in obs {
                guard let t = o.topCandidates(1).first?.string else { continue }
                let m = RegexLibrary.matchesPII(in: t, settings: self.settings)
                if !m.isEmpty {
                    let r = o.boundingBox.scaled(to: CGSize(width: detImage.width, height: detImage.height))
                    for k in m {
                        switch k {
                        case .email: res.emails.append(r)
                        case .phone: res.phones.append(r)
                        case .amount: res.amounts.append(r)
                        case .idcode: res.ids.append(r)
                        default: break
                        }
                    }
                }
            }
        }
        textReq.recognitionLevel = .accurate; textReq.usesLanguageCorrection = true
        reqs.append(textReq)
        try? handler.perform(reqs)
        if scale < 1.0 {
            let inv = 1.0/scale
            func S(_ a:[CGRect])->[CGRect]{ a.map{ CGRect(x:$0.origin.x*inv,y:$0.origin.y*inv,width:$0.size.width*inv,height:$0.size.height*inv) } }
            res.faces=S(res.faces); res.emails=S(res.emails); res.phones=S(res.phones); res.amounts=S(res.amounts); res.ids=S(res.ids); res.barcodes=S(res.barcodes)
        }
        return res
    }
}
