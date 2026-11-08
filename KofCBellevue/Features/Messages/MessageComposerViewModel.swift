import Foundation
import Combine
@MainActor
final class MessageComposerViewModel: ObservableObject {
    @Published var draft: MessageDraft
    init(recipient: KoCRecipient) {
        var value = MessageDraft()
        value.phone = recipient.phoneNumbers.first ?? ""
        value.email = recipient.emailAddresses.first ?? ""
        value.useSMS = !value.phone.isEmpty
        value.useEmail = !value.email.isEmpty
        draft = value
    }
}
@MainActor
final class RecipientPickerViewModel: ObservableObject {
    @Published var members: [KoCRecipient] = []
    @Published var isLoading = false
    @Published var errorText: String?
    @Published var source = "Choose a directory"
    let database: DatabaseRecipientRepository
    init(database: DatabaseRecipientRepository) { self.database = database }
    func loadDatabase() async { await load(database, label: "Church members") }
    func loadContacts() async { await load(PhoneContactsRepository(), label: "Phone contacts") }
    private func load(_ repository: any RecipientRepository, label: String) async {
        isLoading = true; errorText = nil; members = []; source = label
        defer { isLoading = false }
        do { members = try await repository.loadRecipients() }
        catch { errorText = error.localizedDescription }
    }
}
