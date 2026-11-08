import UIKit

struct BannerImageStore {
    private var directory: URL {
        get throws {
            let root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let folder = root.appendingPathComponent("CouncilBanners", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            return folder
        }
    }
    var metadataURL: URL { get throws { try directory.appendingPathComponent("banners.json") } }

    func image(named filename: String?) -> UIImage? {
        guard let filename, let folder = try? directory else { return nil }
        return UIImage(contentsOfFile: folder.appendingPathComponent(filename).path)
    }

    func save(_ data: Data) throws -> String {
        guard data.count <= 20 * 1024 * 1024 else { throw BannerStoreError.tooLarge }
        guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else {
            throw BannerStoreError.invalidImage
        }
        let scale = min(1, 2048 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let png = resized.pngData() else { throw BannerStoreError.invalidImage }
        let name = UUID().uuidString + ".png"
        try png.write(to: directory.appendingPathComponent(name), options: .atomic)
        return name
    }

    func remove(_ filename: String?) {
        guard let filename, let folder = try? directory else { return }
        try? FileManager.default.removeItem(at: folder.appendingPathComponent(filename))
    }
}

enum BannerStoreError: LocalizedError {
    case invalidImage, tooLarge
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Choose a valid JPEG or PNG image."
        case .tooLarge: return "Choose an image smaller than 20 MB."
        }
    }
}
