import CoreGraphics
import UIKit
extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        let w = self.size.width * size.width
        let h = self.size.height * size.height
        let x = self.origin.x * size.width
        let yTop = (1 - (self.origin.y + self.size.height)) * size.height
        return CGRect(x: x, y: yTop, width: w, height: h)
    }
}
