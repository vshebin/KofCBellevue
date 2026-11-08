import SwiftUI
struct RecipientPickerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: RecipientPickerViewModel
    @State private var search = ""
    @State private var manualName = ""
    @State private var manualPhone = ""
    @State private var manualEmail = ""
    init(database: DatabaseRecipientRepository) {
        _model = StateObject(wrappedValue: RecipientPickerViewModel(database: database))
    }
    private var filtered: [KoCRecipient] {
        model.members.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
    }
    var body: some View {
        NavigationStack {
            List {
                Section("Directory") {
                    Text(model.source).foregroundStyle(.secondary)
                    if model.database.isConfigured {
                        Button("Load church members") { Task { await model.loadDatabase() } }.disabled(model.isLoading)
                    } else { Text("Church database is not configured yet.").font(.footnote) }
                    Button("Use phone contacts") { Task { await model.loadContacts() } }.disabled(model.isLoading)
                    Text("Only permitted contacts are read. They are not uploaded or registered as church members.").font(.caption).foregroundStyle(.secondary)
                }
                if model.isLoading { ProgressView("Loading…") }
                if let error = model.errorText { Text(error).foregroundStyle(.red) }
                Section("Recipients") {
                    if !model.isLoading && filtered.isEmpty { Text("No members to display.").foregroundStyle(.secondary) }
                    ForEach(filtered) { member in
                        NavigationLink { ComposeMessageScreen(recipient: member) } label: {
                            Label(member.name, systemImage: "person.crop.circle")
                        }
                    }
                }
                Section("Or enter a recipient manually") {
                    TextField("Name (optional)", text: $manualName)
                    TextField("Phone number", text: $manualPhone).keyboardType(.phonePad)
                    TextField("Email address", text: $manualEmail).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                    NavigationLink("Continue") {
                        ComposeMessageScreen(recipient: KoCRecipient(id: UUID().uuidString, name: manualName.isEmpty ? "Recipient" : manualName, phoneNumbers: manualPhone.isEmpty ? [] : [manualPhone], emailAddresses: manualEmail.isEmpty ? [] : [manualEmail]))
                    }.disabled(manualPhone.trimmingCharacters(in: .whitespaces).isEmpty && manualEmail.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .searchable(text: $search, prompt: "Search names")
            .navigationTitle("New message").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .task { if model.database.isConfigured { await model.loadDatabase() } }
        }
    }
}
