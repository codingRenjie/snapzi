import UIKit

enum ImageSquareProcessor {
    static let outputSide: CGFloat = 1024

    static func squareCrop(_ image: UIImage) -> UIImage {
        let image = image.normalizedUpOrientation()
        let side = min(image.size.width, image.size.height)
        let originX = (image.size.width - side) / 2
        let originY = (image.size.height - side) / 2
        let scale = image.scale
        let cropRect = CGRect(x: originX * scale, y: originY * scale, width: side * scale, height: side * scale)
        guard let cg = image.cgImage?.cropping(to: cropRect) else { return image }
        let cropped = UIImage(cgImage: cg, scale: scale, orientation: image.imageOrientation)
        return resize(cropped, to: outputSide)
    }

    static func resize(_ image: UIImage, to side: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: CGSize(width: side, height: side)))
        }
    }
}
