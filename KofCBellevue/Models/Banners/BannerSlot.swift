import Foundation

enum BannerSlot: Int, Codable, CaseIterable, Identifiable {
    case welcome = 1, second, third, fourth, minutes
    var id: Int { rawValue }
    var title: String { self == .minutes ? "Banner 5 — Meeting Minutes" : "Banner \(rawValue)" }
    var isEditable: Bool { (2...4).contains(rawValue) }
}
