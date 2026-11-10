//
//  FirebaseMessageContacts.swift
//  KofCBellevue
//
//  Created by Shebin on 11/9/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class FirebaseMessageContacts {
    private enum ContactError: LocalizedError {
        case signInRequired
        case missingAddress

        var errorDescription: String? {
            switch self {
            case .signInRequired:
                return "Please log in to access saved contacts."

            case .missingAddress:
                return "Enter a phone number or email address."
            }
        }
    }

    private func contactsCollection() throws -> CollectionReference {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw ContactError.signInRequired
        }

        return Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("messageContacts")
    }

    func loadContacts() async throws -> [KoCRecipient] {
        let collection = try contactsCollection()
        let snapshot = try await collection.getDocuments()

        return snapshot.documents.compactMap { document in
            let data = document.data()

            let phones = data["phoneNumbers"] as? [String] ?? []
            let emails = data["emailAddresses"] as? [String] ?? []

            guard !phones.isEmpty || !emails.isEmpty else {
                return nil
            }

            let storedName = data["name"] as? String ?? ""
            let fallbackName = emails.first ?? phones.first ?? "Recipient"

            return KoCRecipient(
                id: document.documentID,
                name: storedName.isEmpty ? fallbackName : storedName,
                phoneNumbers: phones,
                emailAddresses: emails
            )
        }
        .sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name)
                == .orderedAscending
        }
    }

    func saveContact(
        _ recipient: KoCRecipient
    ) async throws {
        guard !recipient.phoneNumbers.isEmpty
                || !recipient.emailAddresses.isEmpty else {
            throw ContactError.missingAddress
        }

        let collection = try contactsCollection()

        try await collection
            .document(recipient.id)
            .setData([
                "name": recipient.name,
                "phoneNumbers": recipient.phoneNumbers,
                "emailAddresses": recipient.emailAddresses,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }
}
