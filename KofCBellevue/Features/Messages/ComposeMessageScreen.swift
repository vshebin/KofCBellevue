//
//  ComposeMessageScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/9/26.
//

import SwiftUI

struct ComposeMessageScreen: View {
    let database: DatabaseRecipientRepository

    @Environment(\.dismiss) private var dismiss

    @State private var selectedRecipients: [KoCRecipient]

    @State private var subject =
        "Sacred heart knights of Columbus: \(Date())"

    @State private var messageBody = ""

    @State private var showRecipientPicker = false
    @State private var showDeliveryOptions = false
    @State private var reviewDestination: ReviewDestination?

    @State private var sendToAllKnights = false
    @State private var isLoadingAllKnights = false
    @State private var allKnightsError: String?

    @State private var selectionBeforeAllKnights: [KoCRecipient] = []

    init(
        recipient: KoCRecipient? = nil,
        database: DatabaseRecipientRepository =
            DatabaseRecipientRepository()
    ) {
        self.database = database

        let initialRecipients: [KoCRecipient]

        if let recipient = recipient {
            initialRecipients = [recipient]
        } else {
            initialRecipients = []
        }

        _selectedRecipients = State(
            initialValue: initialRecipients
        )
    }

    private struct ReviewDestination {
        let recipients: [KoCRecipient]
        let draft: MessageDraft
    }

    // MARK: - Recipient information

    private var recipientSummary: String {
        if isLoadingAllKnights {
            return "Loading members…"
        }

        if sendToAllKnights {
            return "All Knights (\(selectedRecipients.count))"
        }

        if selectedRecipients.isEmpty {
            return "Select recipients"
        }

        if selectedRecipients.count == 1 {
            return selectedRecipients[0].name
        }

        return "\(selectedRecipients.count) members selected"
    }

    private var recipientTextColor: Color {
        if selectedRecipients.isEmpty {
            return .secondary
        }

        return .primary
    }

    private var missingPhones: Int {
        selectedRecipients.filter { recipient in
            usableAddress(recipient.phoneNumbers) == nil
        }.count
    }

    private var missingEmails: Int {
        selectedRecipients.filter { recipient in
            usableAddress(recipient.emailAddresses) == nil
        }.count
    }

    private var hasRecipients: Bool {
        !selectedRecipients.isEmpty
    }

    private var hasMessage: Bool {
        !messageBody.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    private var canSendSMS: Bool {
        hasRecipients && missingPhones == 0
    }

    private var canSendEmail: Bool {
        hasRecipients && missingEmails == 0
    }

    private var canContinue: Bool {
        let hasDeliveryMethod = canSendSMS || canSendEmail

        return !isLoadingAllKnights
            && hasRecipients
            && hasMessage
            && hasDeliveryMethod
    }

    private var shouldShowDeliveryWarning: Bool {
        guard hasRecipients else {
            return false
        }

        return missingPhones > 0 || missingEmails > 0
    }

    private var phoneWarning: String {
        """
        \(missingPhones) selected member(s) have no phone number. \
        Text-message delivery is unavailable for this selection.
        """
    }

    private var emailWarning: String {
        """
        \(missingEmails) selected member(s) have no email address. \
        Email delivery is unavailable for this selection.
        """
    }

    // MARK: - Bindings

    private var allKnightsBinding: Binding<Bool> {
        Binding(
            get: {
                sendToAllKnights
            },
            set: { enabled in
                guard !isLoadingAllKnights else {
                    return
                }

                if enabled {
                    // Set immediately to prevent duplicate requests.
                    isLoadingAllKnights = true
                    allKnightsError = nil

                    Task {
                        await selectAllKnights()
                    }
                } else {
                    restorePreviousSelection()
                }
            }
        )
    }

    private var isReviewPresented: Binding<Bool> {
        Binding(
            get: {
                reviewDestination != nil
            },
            set: { presented in
                if !presented {
                    reviewDestination = nil
                }
            }
        )
    }

    // MARK: - Main screen

    var body: some View {
        composerForm
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                composerToolbar
            }
            .sheet(isPresented: $showRecipientPicker) {
                recipientPicker
            }
            .confirmationDialog(
                "How would you like to send?",
                isPresented: $showDeliveryOptions,
                titleVisibility: .visible
            ) {
                deliveryActions
            }
            .navigationDestination(
                isPresented: isReviewPresented
            ) {
                reviewScreen
            }
            .interactiveDismissDisabled(isLoadingAllKnights)
    }

    private var composerForm: some View {
        Form {
            recipientsSection

            if shouldShowDeliveryWarning {
                deliveryWarningSection
            }

            subjectSection

            messageSection
        }
    }

    // MARK: - Recipients

    private var recipientsSection: some View {
        Section {
            Button {
                showRecipientPicker = true
            } label: {
                recipientLabel
            }
            .buttonStyle(.plain)
            .disabled(isLoadingAllKnights)

            Toggle(
                "Send to all Knights",
                isOn: allKnightsBinding
            )
            .disabled(isLoadingAllKnights)

            if isLoadingAllKnights {
                ProgressView("Selecting all Knights…")
            }

            if let error = allKnightsError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
            }
        } footer: {
            Text(
                """
                All Knights selects everyone returned by the \
                club directory, not your phone contacts or private \
                saved contacts. Nothing is sent automatically.
                """
            )
        }
    }

    private var recipientLabel: some View {
        HStack(spacing: 12) {
            Text("To")
                .foregroundStyle(Color.primary)

            Spacer()

            Text(recipientSummary)
                .foregroundStyle(recipientTextColor)
                .lineLimit(1)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        .frame(minHeight: 32)
        .contentShape(Rectangle())
    }

    // MARK: - Delivery warnings

    private var deliveryWarningSection: some View {
        Section("Delivery availability") {
            if missingPhones > 0 {
                Text(phoneWarning)
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }

            if missingEmails > 0 {
                Text(emailWarning)
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    // MARK: - Subject

    private var subjectSection: some View {
        Section {
            TextField(
                "Subject",
                text: $subject,
                axis: .vertical
            )
            .textInputAutocapitalization(.sentences)
        } header: {
            Text("Subject")
        } footer: {
            Text("It’s only for emails.")
        }
    }

    // MARK: - Message

    private var messageSection: some View {
        Section("Message") {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $messageBody)
                    .frame(minHeight: 240)
                    .accessibilityLabel("Message")

                if messageBody.isEmpty {
                    Text("Write your message…")
                        .foregroundStyle(Color.secondary)
                        .padding(.leading, 5)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var composerToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
            .disabled(isLoadingAllKnights)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Continue") {
                showDeliveryOptions = true
            }
            .disabled(!canContinue)
        }
    }

    // MARK: - Recipient picker

    private var recipientPicker: some View {
        RecipientPickerScreen(
            database: database,
            selectedRecipients: selectedRecipients,
            onSelect: { recipients in
                applyManualSelection(recipients)
            }
        )
    }

    // MARK: - Delivery options

    @ViewBuilder
    private var deliveryActions: some View {
        Button("Text message") {
            prepareReview(useEmail: false)
        }
        .disabled(!canSendSMS)

        Button("Email") {
            prepareReview(useEmail: true)
        }
        .disabled(!canSendEmail)

        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Review destination

    @ViewBuilder
    private var reviewScreen: some View {
        if let destination = reviewDestination {
            MessageReviewScreen(
                recipients: destination.recipients,
                draft: destination.draft
            )
        }
    }

    // MARK: - All Knights selection

    @MainActor
    private func selectAllKnights() async {
        defer {
            isLoadingAllKnights = false
        }

        do {
            let members = try await database.loadRecipients()

            var seenIDs = Set<String>()

            let uniqueMembers = members.filter { member in
                seenIDs.insert(member.id).inserted
            }

            guard !uniqueMembers.isEmpty else {
                sendToAllKnights = false
                allKnightsError =
                    "No members were returned by the directory."
                return
            }

            selectionBeforeAllKnights = selectedRecipients

            selectedRecipients = uniqueMembers.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name)
                    == .orderedAscending
            }

            sendToAllKnights = true
            allKnightsError = nil
        } catch {
            // Leave the previous recipients unchanged.
            sendToAllKnights = false

            allKnightsError =
                "Could not select all Knights: "
                + error.localizedDescription
        }
    }

    private func restorePreviousSelection() {
        if sendToAllKnights {
            selectedRecipients = selectionBeforeAllKnights
        }

        sendToAllKnights = false
        selectionBeforeAllKnights = []
        allKnightsError = nil
    }

    private func applyManualSelection(
        _ recipients: [KoCRecipient]
    ) {
        let previousIDs = Set(
            selectedRecipients.map(\.id)
        )

        let updatedIDs = Set(
            recipients.map(\.id)
        )

        selectedRecipients = recipients
        allKnightsError = nil

        // Keep All Knights enabled if the picker selection
        // was opened and confirmed without changing membership.
        if previousIDs != updatedIDs {
            sendToAllKnights = false
            selectionBeforeAllKnights = []
        }
    }

    // MARK: - Helpers

    private func usableAddress(
        _ values: [String]
    ) -> String? {
        for value in values {
            let trimmed = value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return nil
    }

    private func prepareReview(useEmail: Bool) {
        guard canContinue else {
            return
        }

        if useEmail {
            guard canSendEmail else {
                return
            }
        } else {
            guard canSendSMS else {
                return
            }
        }

        var draft = MessageDraft()

        if useEmail {
            let trimmedSubject = subject.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            if trimmedSubject.isEmpty {
                draft.subject = "Sacred heart knights of Columbus"
            } else {
                draft.subject = trimmedSubject
            }
        } else {
            draft.subject = ""
        }

        draft.body = messageBody.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // These single-address fields keep the draft compatible.
        // MessageReviewScreen uses the full recipients array.
        if let firstRecipient = selectedRecipients.first {
            draft.phone =
                usableAddress(firstRecipient.phoneNumbers) ?? ""

            draft.email =
                usableAddress(firstRecipient.emailAddresses) ?? ""
        }

        draft.useSMS = !useEmail
        draft.useEmail = useEmail

        reviewDestination = ReviewDestination(
            recipients: selectedRecipients,
            draft: draft
        )
    }
}
