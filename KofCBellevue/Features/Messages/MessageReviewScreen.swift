import SwiftUI
import MessageUI
struct MessageReviewScreen: View {
    let recipient: KoCRecipient
    let draft: MessageDraft
    @State private var activeComposer: Composer?
    @State private var smsStatus = "Not opened"
    @State private var emailStatus = "Not opened"
    private enum Composer: String, Identifiable {
        case sms, email
        var id: String { rawValue }
    }
    var body: some View {
        List {
            Section("Recipient") { Text(recipient.name) }
            Section("Subject") { Text(draft.subject.isEmpty ? "(No subject)" : draft.subject) }
            Section("Description") { Text(draft.body) }
            Section {
                Text("Each channel requires a separate confirmation. Complete one, then open the other. Nothing is sent automatically.")
                Text("Composers allow final edits. Changes made inside one composer do not update the other channel.").font(.footnote).foregroundStyle(.secondary)
            }
            if draft.useSMS {
                Section("SMS") {
                    Text(draft.phone)
                    Button("Open SMS composer") { activeComposer = .sms }.disabled(!MFMessageComposeViewController.canSendText())
                    if !MFMessageComposeViewController.canSendText() { Text("SMS is unavailable on this device.").foregroundStyle(.secondary) }
                    Text(smsStatus).font(.footnote)
                }
            }
            if draft.useEmail {
                Section("Email") {
                    Text(draft.email)
                    Button("Open email composer") { activeComposer = .email }.disabled(!MFMailComposeViewController.canSendMail())
                    if !MFMailComposeViewController.canSendMail() { Text("Configure an account in Apple Mail on a real device to use this composer.").foregroundStyle(.secondary) }
                    Text(emailStatus).font(.footnote)
                }
            }
            Section { Text("No conversation history is saved. Back navigation or closing this draft can discard its contents.").font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("Review").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeComposer) { composer in
            switch composer {
            case .sms:
                SMSComposerView(phone: draft.phone, body: draft.smsBody) { result in
                    smsStatus = result; activeComposer = nil
                }
            case .email:
                EmailComposerView(email: draft.email, subject: draft.subject, body: draft.body) { result in
                    emailStatus = result; activeComposer = nil
                }
            }
        }
    }
}
