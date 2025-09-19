import UIKit
final class RedactionRenderer {
    func applyMasks(on image: UIImage, boxes: [CGRect]) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let w = cg.width, h = cg.height, cs = CGColorSpaceCreateDeviceRGB()
        
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let outputImage = ctx.makeImage() else {
            return image
        }
        
        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        ctx.setFillColor(UIColor.black.cgColor)
        
        for var r in boxes {
            r = r.integral
            let clamp = r.intersection(CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))
            if !clamp.isNull && clamp.width > 1 && clamp.height > 1 { 
                ctx.fill(clamp) 
            }
        }
        
        return UIImage(cgImage: outputImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
