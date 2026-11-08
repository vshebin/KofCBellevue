import SwiftUI
import Combine

@MainActor
final class BannerManagementViewModel: ObservableObject {
    @Published private(set) var banners: [BannerContent] = []
    @Published var errorMessage: String?
    // Integration point only: the minutes feature supplies this after publishing.
    // It is intentionally not a fabricated MOM record or an editable announcement.
    @Published private(set) var latestMinutesBanner: BannerContent?
    let imageStore = BannerImageStore()
    private let repository: any BannerRepository

    init(repository: any BannerRepository) {
        self.repository = repository
        do { banners = try repository.load().filter { $0.slot.isEditable } }
        catch { errorMessage = "Could not load saved banners: \(error.localizedDescription)" }
    }

    func content(for slot: BannerSlot) -> BannerContent {
        banners.first { $0.slot == slot } ?? BannerContent(slot: slot)
    }

    var visibleBanners: [BannerContent] {
        let welcome = BannerContent(slot: .welcome, title: "Welcome, brothers", subtitle: "Stay connected with your Bellevue community.", imageDescription: "Council church", isPublished: true)
        var result = [welcome]
        result += banners.filter {
            $0.slot.isEditable && $0.isPublished && $0.isEnabled && imageStore.image(named: $0.imageFilename) != nil
        }.sorted { $0.slot.rawValue < $1.slot.rawValue }
        if let minutes = latestMinutesBanner, minutes.isPublished, minutes.isEnabled { result.append(minutes) }
        return result
    }

    func setLatestMinutesBanner(_ banner: BannerContent?) {
        guard banner == nil || banner?.slot == .minutes else { return }
        latestMinutesBanner = banner
    }

    func save(_ content: BannerContent, imageData: Data?, publish: Bool) throws {
        guard content.slot.isEditable else { return }
        var updated = content
        let old = banners.first { $0.slot == content.slot }
        var newFilename: String?
        do {
            if let imageData {
                newFilename = try imageStore.save(imageData)
                updated.imageFilename = newFilename
            }
            guard imageStore.image(named: updated.imageFilename) != nil else { throw BannerStoreError.invalidImage }
            updated.isPublished = publish
            var next = banners.filter { $0.slot != updated.slot }
            next.append(updated)
            try repository.save(next)
            banners = next
            if newFilename != nil { imageStore.remove(old?.imageFilename) }
        } catch {
            imageStore.remove(newFilename)
            throw error
        }
    }

    func remove(_ slot: BannerSlot) throws {
        guard slot.isEditable else { return }
        let old = content(for: slot)
        let next = banners.filter { $0.slot != slot }
        try repository.save(next)
        banners = next
        imageStore.remove(old.imageFilename)
    }
}
