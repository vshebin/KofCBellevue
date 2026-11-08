import Foundation
// Future server integration: enforce sender permissions and recipient consent there.
protocol MessageDeliveryService {
    func enqueue(draft: MessageDraft, recipient: KoCRecipient, channels: [DeliveryChannel]) async throws
}
struct UnconfiguredMessageDeliveryService: MessageDeliveryService {
    func enqueue(draft: MessageDraft, recipient: KoCRecipient, channels: [DeliveryChannel]) async throws {
        throw RecipientRepositoryError.notConfigured
    }
}
