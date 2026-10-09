import CoreImage
import UIKit

/// On-device label. Encodes the item code when one is stored, otherwise the id.
enum LabelPlate {
    static func image(for text: String, side: CGFloat) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(text.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let extent = output.extent
        guard extent.width > 0 else { return nil }
        let scale = side / extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let bounds = scaled.extent.integral
        guard let context = CGContext(
            data: nil,
            width: Int(bounds.width),
            height: Int(bounds.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        let ci = CIContext(options: nil)
        guard let cg = ci.createCGImage(scaled, from: bounds) else { return nil }
        context.draw(cg, in: CGRect(origin: .zero, size: bounds.size))
        guard let plate = context.makeImage() else { return nil }
        return UIImage(cgImage: plate)
    }
}
