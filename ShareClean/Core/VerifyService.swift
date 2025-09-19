import UIKit
import Vision

struct VerifyResult { let leakBoxes: [CGRect]; var hasLeaks: Bool { !leakBoxes.isEmpty } }

final class VerifyService {
    let settings: DetectionSettings
    init(settings: DetectionSettings) { self.settings = settings }
    func verify(image: UIImage, targeted: [PIIType]) -> VerifyResult {
        guard let cg = image.cgImage else { return VerifyResult(leakBoxes: []) }
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        var leaks: [CGRect] = []
        let textReq = VNRecognizeTextRequest { rq,_ in
            let obs = (rq.results as? [VNRecognizedTextObservation]) ?? []
            for o in obs {
                guard let t = o.topCandidates(1).first?.string else { continue }
                let m = RegexLibrary.matchesPII(in: t, settings: self.settings)
                if !m.isEmpty { leaks.append(o.boundingBox.scaled(to: CGSize(width: cg.width, height: cg.height))) }
            }
        }
        textReq.recognitionLevel = .accurate
        try? handler.perform([textReq])
        return VerifyResult(leakBoxes: leaks)
    }
}
