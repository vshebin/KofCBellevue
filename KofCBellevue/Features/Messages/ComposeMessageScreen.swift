import SwiftUI
struct ComposeMessageScreen: View {
    let recipient: KoCRecipient
    @StateObject private var model: MessageComposerViewModel
    init(recipient: KoCRecipient) {
        self.recipient = recipient
        _model = StateObject(wrappedValue: MessageComposerViewModel(recipient: recipient))
    }
    var body: some View {
        Form {
            Section("To") { Text(recipient.name) }
            Section("Subject — optional") {
                TextField("Subject", text: $model.draft.subject, axis: .vertical)
            }
            Section("Message description") {
                TextEditor(text: $model.draft.body).frame(minHeight: 160)
            }
            Section("Delivery options") {
                Toggle("SMS", isOn: $model.draft.useSMS).disabled(recipient.phoneNumbers.isEmpty)
                if model.draft.useSMS {
                    Picker("Phone", selection: $model.draft.phone) {
                        ForEach(recipient.phoneNumbers, id: \.self) { Text($0).tag($0) }
                    }
                }
                Toggle("Email", isOn: $model.draft.useEmail).disabled(recipient.emailAddresses.isEmpty)
                if model.draft.useEmail {
                    Picker("Email address", selection: $model.draft.email) {
                        ForEach(recipient.emailAddresses, id: \.self) { Text($0).tag($0) }
                    }
                }
                Label("App delivery requires a backend", systemImage: "lock").font(.footnote).foregroundStyle(.secondary)
            }
            Section("App preview rule") {
                Text(model.draft.preview.isEmpty ? "No preview" : model.draft.preview)
                Text("Subject first; description when subject is empty. External SMS/email previews are controlled by their apps.").font(.caption).foregroundStyle(.secondary)
            }
            Section {
                NavigationLink("Review message") {
                    MessageReviewScreen(recipient: recipient, draft: model.draft)
                }.disabled(!model.draft.isValid)
            }
        }
        .navigationTitle("Compose").navigationBarTitleDisplayMode(.inline)
    }
}
