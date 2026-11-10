//
//  DatabaseRecipientRepository.swift
//  KofCBellevue
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct DatabaseRecipientRepository: RecipientRepository {
    let fetch: (() async throws -> [KoCRecipient])?

    init(
        fetch: (() async throws -> [KoCRecipient])? = nil
    ) {
        self.fetch = fetch ?? {
            guard Auth.auth().currentUser != nil else {
                throw DirectoryError.signInRequired
            }

            let snapshot = try await Firestore.firestore()
                .collection("knightsDirectory")
                .getDocuments(source: .server)

            return snapshot.documents.compactMap { document in
                let data = document.data()

                let rawName = data["name"] as? String ?? ""

                let name = rawName.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                let phones =
                    data["phoneNumbers"] as? [String] ?? []

                let emails =
                    data["emailAddresses"] as? [String] ?? []

                guard !name.isEmpty,
                      !phones.isEmpty || !emails.isEmpty else {
                    return nil
                }

                return KoCRecipient(
                    id: document.documentID,
                    name: name,
                    phoneNumbers: phones,
                    emailAddresses: emails
                )
            }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name)
                    == .orderedAscending
            }
        }
    }

    // Indicates that a query is configured.
    // It does not guarantee network access or permission.
    var isConfigured: Bool {
        fetch != nil
    }

    func loadRecipients() async throws -> [KoCRecipient] {
        guard let fetch else {
            throw DirectoryError.notConfigured
        }

        return try await fetch()
    }

    private enum DirectoryError: LocalizedError {
        case signInRequired
        case notConfigured

        var errorDescription: String? {
            switch self {
            case .signInRequired:
                return "Please log in to view the member directory."

            case .notConfigured:
                return "The member directory is not configured."
            }
        }
    }
}
