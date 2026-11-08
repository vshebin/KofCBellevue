import Foundation

@MainActor
final class LocalBannerRepository: BannerRepository {
    private let store = BannerImageStore()
    func load() throws -> [BannerContent] {
        let url = try store.metadataURL
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([BannerContent].self, from: Data(contentsOf: url))
    }
    func save(_ banners: [BannerContent]) throws {
        try JSONEncoder().encode(banners).write(to: store.metadataURL, options: .atomic)
    }
}
