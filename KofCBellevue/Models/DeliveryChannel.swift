import Foundation
enum DeliveryChannel: String, Identifiable, CaseIterable {
    case sms = "SMS", email = "Email", app = "App notification"
    var id: String { rawValue }
}
