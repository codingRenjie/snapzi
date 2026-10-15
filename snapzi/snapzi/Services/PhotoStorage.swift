import UIKit

enum PhotoStorage {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let photos = base.appendingPathComponent("CapturedPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: photos.path) {
            try? FileManager.default.createDirectory(at: photos, withIntermediateDirectories: true)
        }
        return photos
    }

    static func save(_ image: UIImage) throws -> String {
        let name = UUID().uuidString + ".jpg"
        let url = directory.appendingPathComponent(name)
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw SaveError.encodingFailed
        }
        try data.write(to: url, options: .atomic)
        return name
    }

    static func url(forRelativePath path: String) -> URL {
        directory.appendingPathComponent(path)
    }

    static func load(relativePath: String) -> UIImage? {
        let url = url(forRelativePath: relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(relativePath: String) {
        let url = url(forRelativePath: relativePath)
        try? FileManager.default.removeItem(at: url)
    }

    static func makePlaceholder(word: String, keyword: String) -> UIImage {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let line1 = "我们拍的"
            let line2 = word
            (line1 as NSString).draw(at: CGPoint(x: 40, y: 200), withAttributes: attrs)
            (line2 as NSString).draw(at: CGPoint(x: 40, y: 280), withAttributes: attrs)
            let small: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            ("关键字：\(keyword)" as NSString).draw(at: CGPoint(x: 40, y: 380), withAttributes: small)
        }
    }

    enum SaveError: Error {
        case encodingFailed
    }
}
