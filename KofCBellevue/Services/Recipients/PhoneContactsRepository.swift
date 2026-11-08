import Foundation
import Contacts
struct PhoneContactsRepository: RecipientRepository {
    func loadRecipients() async throws -> [KoCRecipient] {
        let granted = try await CNContactStore().requestAccess(for: .contacts)
        guard granted else {
            throw NSError(domain: "KoCContacts", code: 1, userInfo: [NSLocalizedDescriptionKey: "Contacts access was not granted. You can enter a recipient manually, or allow access in iPhone Settings."])
        }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let keys: [CNKeyDescriptor] = [CNContactIdentifierKey as CNKeyDescriptor, CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactOrganizationNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor]
                    let request = CNContactFetchRequest(keysToFetch: keys)
                    var members: [KoCRecipient] = []
                    try CNContactStore().enumerateContacts(with: request) { contact, _ in
                        let phones = contact.phoneNumbers.map { $0.value.stringValue }
                        let emails = contact.emailAddresses.map { String($0.value) }
                        guard !phones.isEmpty || !emails.isEmpty else { return }
                        let full = [contact.givenName, contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
                        let name = full.isEmpty ? (contact.organizationName.isEmpty ? (emails.first ?? phones.first ?? "Contact") : contact.organizationName) : full
                        members.append(KoCRecipient(id: contact.identifier, name: name, phoneNumbers: phones, emailAddresses: emails))
                    }
                    continuation.resume(returning: members.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
                } catch { continuation.resume(throwing: error) }
            }
        }
    }
}
