import UIKit
import ImageIO
import UniformTypeIdentifiers

enum EXIFStripper {
    static func strip(_ image: UIImage, quality: CGFloat = 0.9) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else { return image }
        let opts: NSDictionary = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(dest, cg, opts)
        CGImageDestinationFinalize(dest)
        if let out = UIImage(data: data as Data) { return out }
        return image
    }
}
