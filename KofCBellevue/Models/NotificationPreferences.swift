import Foundation
import UserNotifications
enum NotificationTone: String, CaseIterable, Identifiable {
    case defaultTone = "Default", gentleBell = "Gentle bell", softChime = "Soft chime", none = "None"
    var id: String { rawValue }
    var fileName: String? {
        switch self {
        case .gentleBell: return "gentle-bell.wav"
        case .softChime: return "soft-chime.wav"
        default: return nil
        }
    }
    var isAvailable: Bool {
        guard let fileName else { return true }
        return Bundle.main.url(forResource: fileName, withExtension: nil) != nil
    }
    var sound: UNNotificationSound? {
        if self == .none { return nil }
        guard let fileName, isAvailable else { return .default }
        return UNNotificationSound(named: UNNotificationSoundName(rawValue: fileName))
    }
}
