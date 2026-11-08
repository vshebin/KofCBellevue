import Foundation

struct BannerContent: Identifiable, Codable, Equatable {
    var slot: BannerSlot
    var title: String = ""
    var subtitle: String = ""
    var imageDescription: String = ""
    var imageFilename: String? = nil
    var isPublished: Bool = false
    var isEnabled: Bool = true
    var id: Int { slot.rawValue }
}
