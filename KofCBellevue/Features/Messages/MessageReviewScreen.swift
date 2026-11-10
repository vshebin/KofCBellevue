//
//  MessageReviewScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/9/26.
//

import SwiftUI
import MessageUI
import CryptoKit

struct MessageReviewScreen: View {
    let recipients: [KoCRecipient]
    let draft: MessageDraft

    @EnvironmentObject private var history: ConversationStore

    @State private var activeComposer: Composer?
    @State private var status = "Not opened"

    init(
        recipients: [KoCRecipient],
        draft: MessageDraft
    ) {
        self.recipients = recipients
        self.draft = draft
    }

    // Preserve compatibility with older single-recipient calls.
    init(
        recipient: KoCRecipient,
        draft: MessageDraft
    ) {
        self.recipients = [recipient]
        self.draft = draft
    }

    private enum Composer: String, Identifiable {
        case sms
        case email

        var id: String { rawValue }
    }

    private var phoneAddresses: [String] {
        uniqueAddresses(
            recipients.compactMap {
                firstAddress($0.phoneNumbers)
            },
            isEmail: false
        )
    }

    private var emailAddresses: [String] {
        uniqueAddresses(
            recipients.compactMap {
                firstAddress($0.emailAddresses)
            },
            isEmail: true
        )
    }

    private var allHavePhone: Bool {
        !recipients.isEmpty
            && recipients.allSatisfy {
                firstAddress($0.phoneNumbers) != nil
            }
    }

    private var allHaveEmail: Bool {
        !recipients.isEmpty
            && recipients.allSatisfy {
                firstAddress($0.emailAddresses) != nil
            }
    }

    private var conversationID: String {
        let ids = Array(Set(recipients.map(\.id))).sorted()

        if ids.count == 1 {
            return "member:\(ids[0])"
        }

        let encoded = (try? JSONEncoder().encode(ids)) ?? Data()

        let hash = SHA256.hash(data: encoded).map {
            String(format: "%02x", $0)
        }.joined()

        return "group:\(hash)"
    }

    private var conversationTitle: String {
        recipients.map(\.name)
            .sorted()
            .joined(separator: ", ")
    }

    var body: some View {
        List {
            Section("Recipients (\(recipients.count))") {
                ForEach(recipients) { recipient in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipient.name)

                        if let address = draft.useEmail
                            ? firstAddress(recipient.emailAddresses)
                            : firstAddress(recipient.phoneNumbers) {
                            Text(address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if draft.useEmail {
                Section {
                    Text(
                        draft.subject.isEmpty
                            ? "(No subject)"
                            : draft.subject
                    )
                } header: {
                    Text("Subject")
                } footer: {
                    Text("It’s only for emails.")
                }
            }

            Section("Message") {
                Text(draft.body)
            }

            if draft.useSMS {
                Section("Text message") {
                    Button("Open SMS composer") {
                        activeComposer = .sms
                    }
                    .disabled(
                        !allHavePhone
                            || !MFMessageComposeViewController.canSendText()
                    )

                    if !allHavePhone {
                        Text(
                            "Every selected recipient needs a phone number."
                        )
                        .foregroundStyle(.secondary)
                    }

                    if !MFMessageComposeViewController.canSendText() {
                        Text("SMS is unavailable on this device.")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if draft.useEmail {
                Section("Email") {
                    Button("Open email composer") {
                        activeComposer = .email
                    }
                    .disabled(
                        !allHaveEmail
                            || !MFMailComposeViewController.canSendMail()
                    )

                    if !allHaveEmail {
                        Text(
                            "Every selected recipient needs an email address."
                        )
                        .foregroundStyle(.secondary)
                    }

                    if !MFMailComposeViewController.canSendMail() {
                        Text(
                            "Configure an account in Apple Mail "
                            + "on a real device to use this composer."
                        )
                        .foregroundStyle(.secondary)
                    }

                    if recipients.count > 1 {
                        Text(
                            "Email addresses are placed in To "
                            + "and are visible to the other recipients."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Status") {
                Text(status)
                    .font(.footnote)
            }

            if let error = history.errorText {
                Section("History storage") {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Text(
                    "Nothing is sent automatically. "
                    + "Confirm sending in the system composer."
                )

                Text(
                    "History saves the original outgoing copy. "
                    + "Edits made in the system composer, delivery, "
                    + "and replies are not synced here."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeComposer) { composer in
            switch composer {
            case .sms:
                KnightsGroupSMSComposer(
                    phones: phoneAddresses,
                    body: draft.body
                ) { sent, result in
                    complete(
                        sent: sent,
                        result: result,
                        channel: "SMS"
                    )
                }

            case .email:
                KnightsGroupEmailComposer(
                    emails: emailAddresses,
                    subject: draft.subject,
                    body: draft.body
                ) { sent, result in
                    complete(
                        sent: sent,
                        result: result,
                        channel: "Email"
                    )
                }
            }
        }
    }

    private func firstAddress(_ values: [String]) -> String? {
        values.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .first { !$0.isEmpty }
    }

    private func uniqueAddresses(
        _ values: [String],
        isEmail: Bool
    ) -> [String] {
        var seen = Set<String>()

        return values.filter { value in
            let key: String

            if isEmail {
                key = value.lowercased()
            } else {
                key = value.filter {
                    "0123456789".contains($0)
                }
            }

            return seen.insert(key).inserted
        }
    }

    private func complete(
        sent: Bool,
        result: String,
        channel: String
    ) {
        status = result
        activeComposer = nil

        guard sent else {
            return
        }

        let saved = history.recordOutgoingCopy(
            conversationID: conversationID,
            title: conversationTitle,
            body: draft.body,
            emailSubject: channel == "Email"
                ? draft.subject
                : nil,
            channel: channel
        )

        status += saved
            ? " Outgoing copy saved."
            : " Could not save the outgoing copy."
    }
}

// MARK: - Multiple-recipient SMS composer

private struct KnightsGroupSMSComposer:
    UIViewControllerRepresentable {

    let phones: [String]
    let body: String
    let completion: (Bool, String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(
        context: Context
    ) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()

        controller.recipients = phones
        controller.body = body
        controller.messageComposeDelegate = context.coordinator

        return controller
    }

    func updateUIViewController(
        _ controller: MFMessageComposeViewController,
        context: Context
    ) {}

    final class Coordinator:
        NSObject,
        MFMessageComposeViewControllerDelegate {

        let completion: (Bool, String) -> Void

        init(
            completion: @escaping (Bool, String) -> Void
        ) {
            self.completion = completion
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            switch result {
            case .sent:
                completion(
                    true,
                    "SMS submitted. Delivery is not confirmed."
                )

            case .cancelled:
                completion(false, "SMS cancelled.")

            case .failed:
                completion(false, "SMS failed.")

            @unknown default:
                completion(false, "SMS status unknown.")
            }
        }
    }
}

// MARK: - Multiple-recipient email composer

private struct KnightsGroupEmailComposer:
    UIViewControllerRepresentable {

    let emails: [String]
    let subject: String
    let body: String
    let completion: (Bool, String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(
        context: Context
    ) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()

        controller.setToRecipients(emails)
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        controller.mailComposeDelegate = context.coordinator

        return controller
    }

    func updateUIViewController(
        _ controller: MFMailComposeViewController,
        context: Context
    ) {}

    final class Coordinator:
        NSObject,
        MFMailComposeViewControllerDelegate {

        let completion: (Bool, String) -> Void

        init(
            completion: @escaping (Bool, String) -> Void
        ) {
            self.completion = completion
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            if let error {
                completion(
                    false,
                    "Email failed: \(error.localizedDescription)"
                )
                return
            }

            switch result {
            case .sent:
                completion(
                    true,
                    "Email submitted. Delivery is not confirmed."
                )

            case .saved:
                completion(false, "Email saved as a draft.")

            case .cancelled:
                completion(false, "Email cancelled.")

            case .failed:
                completion(false, "Email failed.")

            @unknown default:
                completion(false, "Email status unknown.")
            }
        }
    }
}
