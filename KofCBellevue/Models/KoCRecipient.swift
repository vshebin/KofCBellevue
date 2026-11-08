import Foundation
struct KoCRecipient: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    var phoneNumbers: [String] = []
    var emailAddresses: [String] = []
}
