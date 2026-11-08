import Foundation

@MainActor
protocol BannerRepository: AnyObject {
    func load() throws -> [BannerContent]
    func save(_ banners: [BannerContent]) throws
}
