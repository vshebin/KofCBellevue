//
//  RecipientPickerScreen.swift
//  KofCBellevue
//

import SwiftUI
import CryptoKit

struct RecipientPickerScreen: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var directoryModel: RecipientPickerViewModel
    @StateObject private var phoneModel: RecipientPickerViewModel

    private let database: DatabaseRecipientRepository
    private let onSelect: ([KoCRecipient]) -> Void

    private let firebaseContacts = FirebaseMessageContacts()

    @State private var selection: [KoCRecipient]

    @State private var savedContacts: [KoCRecipient] = []
    @State private var isLoadingSaved = false
    @State private var savedContactsError: String?

    @State private var hasRequestedPhoneContacts = false

    @State private var search = ""
    @State private var manualAddress = ""
    @State private var manualEntryError: String?

    init(
        database: DatabaseRecipientRepository,
        selectedRecipients: [KoCRecipient] = [],
        onSelect: @escaping ([KoCRecipient]) -> Void
    ) {
        self.database = database
        self.onSelect = onSelect

        _selection = State(
            initialValue: selectedRecipients
        )

        _directoryModel = StateObject(
            wrappedValue: RecipientPickerViewModel(
                database: database
            )
        )

        _phoneModel = StateObject(
            wrappedValue: RecipientPickerViewModel(
                database: database
            )
        )
    }

    // MARK: - Screen

    var body: some View {
        NavigationStack {
            List {
                churchMembersSection

                manualEntrySection

                phoneContactsButtonSection

                if hasRequestedPhoneContacts {
                    phoneContactsSection
                }

                if isLoadingSaved || !savedContacts.isEmpty {
                    savedContactsSection
                }

                if let error = savedContactsError {
                    Section("Saved contacts") {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .navigationTitle("Select Recipients")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $search,
                prompt: "Search names, phones or emails"
            )
            .toolbar {
                pickerToolbar
            }
            .task {
                await loadInitialContacts()
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var pickerToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Done (\(selection.count))") {
                guard addManualRecipient() else {
                    return
                }

                onSelect(selection)
                dismiss()
            }
        }
    }

    // MARK: - Church members

    private var churchMembersSection: some View {
        Section {
            if directoryModel.isLoading {
                ProgressView("Loading church members…")
            } else if let error = directoryModel.errorText {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
            } else if filteredChurchMembers.isEmpty {
                Text(
                    searchQuery.isEmpty
                        ? "No church members available."
                        : "No matching church members."
                )
                .foregroundStyle(Color.secondary)
            } else {
                ForEach(filteredChurchMembers) { recipient in
                    recipientRow(recipient)
                }
            }
        } header: {
            churchMembersHeader
        }
    }

    private var churchMembersHeader: some View {
        HStack(spacing: 10) {
            Text("Church members")

            Button {
                Task {
                    await directoryModel.loadDatabase()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(
                directoryModel.isLoading || !database.isConfigured
            )
            .accessibilityLabel("Refresh church members")

            Spacer()
        }
    }

    private var filteredChurchMembers: [KoCRecipient] {
        filtered(directoryModel.members)
    }

    // MARK: - Manual entry

    private var manualEntrySection: some View {
        Section {
            TextField(
                "Phone number or email",
                text: $manualAddress
            )
            .keyboardType(.default)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .onSubmit {
                _ = addManualRecipient()
            }
            .onChange(of: manualAddress) { _ in
                manualEntryError = nil
            }

            if let error = manualEntryError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }
        } header: {
            Text("Enter manually")
        } footer: {
            Text(
                """
                Press Done on the keyboard to add an address. \
                Then enter another if needed.
                """
            )
        }
    }

    // MARK: - Phone contacts button

    private var phoneContactsButtonSection: some View {
        Section {
            Button {
                hasRequestedPhoneContacts = true

                Task {
                    await phoneModel.loadContacts()
                }
            } label: {
                Label(
                    "Phone contacts",
                    systemImage: "person.crop.circle"
                )
            }
            .disabled(phoneModel.isLoading)
        }
    }

    // MARK: - Phone contacts list

    private var phoneContactsSection: some View {
        Section("Phone contacts") {
            if phoneModel.isLoading {
                ProgressView("Loading phone contacts…")
            } else if let error = phoneModel.errorText {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
            } else if filteredPhoneContacts.isEmpty {
                Text(
                    searchQuery.isEmpty
                        ? "No phone contacts available."
                        : "No matching phone contacts."
                )
                .foregroundStyle(Color.secondary)
            } else {
                ForEach(filteredPhoneContacts) { recipient in
                    recipientRow(recipient)
                }
            }
        }
    }

    private var filteredPhoneContacts: [KoCRecipient] {
        filtered(phoneModel.members)
    }

    // MARK: - Saved Firebase contacts

    private var savedContactsSection: some View {
        Section("Saved contacts") {
            if isLoadingSaved {
                ProgressView("Loading saved contacts…")
            } else if filteredSavedContacts.isEmpty {
                Text("No matching saved contacts.")
                    .foregroundStyle(Color.secondary)
            } else {
                ForEach(filteredSavedContacts) { recipient in
                    recipientRow(recipient)
                }
            }
        }
    }

    private var filteredSavedContacts: [KoCRecipient] {
        filtered(savedContacts)
    }

    // MARK: - Filtering

    private var searchQuery: String {
        search.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private func filtered(
        _ recipients: [KoCRecipient]
    ) -> [KoCRecipient] {
        let query = searchQuery

        guard !query.isEmpty else {
            return recipients
        }

        return recipients.filter { recipient in
            let matchesName =
                recipient.name.localizedCaseInsensitiveContains(query)

            let matchesPhone = recipient.phoneNumbers.contains {
                $0.localizedCaseInsensitiveContains(query)
            }

            let matchesEmail = recipient.emailAddresses.contains {
                $0.localizedCaseInsensitiveContains(query)
            }

            return matchesName || matchesPhone || matchesEmail
        }
    }

    // MARK: - Recipient row

    private func recipientRow(
        _ recipient: KoCRecipient
    ) -> some View {
        let isSelected = selection.contains {
            $0.id == recipient.id
        }

        return Button {
            toggleSelection(recipient)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipient.name)
                        .foregroundStyle(Color.primary)

                    if let address =
                        recipient.emailAddresses.first
                        ?? recipient.phoneNumbers.first,
                       address != recipient.name {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }

                Spacer()

                Image(
                    systemName: isSelected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .foregroundStyle(
                    isSelected
                        ? Color.accentColor
                        : Color.secondary
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(
            isSelected ? "Selected" : "Not selected"
        )
    }

    private func toggleSelection(
        _ recipient: KoCRecipient
    ) {
        if selection.contains(where: {
            $0.id == recipient.id
        }) {
            selection.removeAll {
                $0.id == recipient.id
            }
        } else {
            selection.append(recipient)
        }
    }

    // MARK: - Manual recipient validation

    @discardableResult
    private func addManualRecipient() -> Bool {
        let address = manualAddress.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !address.isEmpty else {
            return true
        }

        let isEmail = address.contains("@")
        let normalized: String

        if isEmail {
            let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#

            guard address.range(
                of: pattern,
                options: .regularExpression
            ) != nil else {
                manualEntryError = "Enter a valid email address."
                return false
            }

            normalized = address.lowercased()
        } else {
            let allowed = CharacterSet(
                charactersIn: "+0123456789 ()-."
            )

            let plusCount = address.filter {
                $0 == "+"
            }.count

            let digits = address.filter {
                "0123456789".contains($0)
            }

            let hasAllowedCharacters =
                address.unicodeScalars.allSatisfy {
                    allowed.contains($0)
                }

            let hasValidLength =
                (7...15).contains(digits.count)

            let hasValidPlus =
                plusCount == 0
                || (plusCount == 1 && address.hasPrefix("+"))

            guard hasAllowedCharacters,
                  hasValidLength,
                  hasValidPlus else {
                manualEntryError = "Enter a valid phone number."
                return false
            }

            normalized =
                (address.hasPrefix("+") ? "+" : "") + digits
        }

        let identity =
            "\(isEmail ? "email" : "phone"):\(normalized)"

        let digest = SHA256.hash(
            data: Data(identity.utf8)
        )

        let contactID = digest.map {
            String(format: "%02x", $0)
        }
        .joined()

        let recipientID = "contact-\(contactID)"

        if !selection.contains(where: {
            $0.id == recipientID
        }) {
            selection.append(
                KoCRecipient(
                    id: recipientID,
                    name: address,
                    phoneNumbers: isEmail ? [] : [normalized],
                    emailAddresses: isEmail ? [normalized] : []
                )
            )
        }

        manualAddress = ""
        manualEntryError = nil

        return true
    }

    // MARK: - Loading

    @MainActor
    private func loadInitialContacts() async {
        if database.isConfigured {
            await directoryModel.loadDatabase()
        } else {
            directoryModel.errorText =
                "The member directory is not configured."
        }

        await loadSavedContacts()
    }

    @MainActor
    private func loadSavedContacts() async {
        guard !isLoadingSaved else {
            return
        }

        isLoadingSaved = true
        savedContactsError = nil

        defer {
            isLoadingSaved = false
        }

        do {
            savedContacts =
                try await firebaseContacts.loadContacts()
        } catch {
            savedContactsError = error.localizedDescription
        }
    }
}
