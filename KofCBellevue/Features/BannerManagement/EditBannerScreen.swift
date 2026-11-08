import SwiftUI
import UniformTypeIdentifiers

struct EditBannerScreen: View {
    @EnvironmentObject private var model: BannerManagementViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: BannerContent
    @State private var imageData: Data?
    @State private var importing = false
    @State private var confirmPublish = false
    @State private var confirmRemove = false
    @State private var errorMessage: String?

    init(content: BannerContent) { _draft = State(initialValue: content) }

    var body: some View {
        Form {
            Section("Banner image") {
                HomeBannerCard(banner: draft, imageOverride: imageData.flatMap { UIImage(data: $0) })
                    .frame(height: 220)
                Button("Choose JPEG or PNG") { importing = true }
                Text("Choose from Files. Maximum file size: 20 MB. The preview may crop the image to fit.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Optional text over image") {
                TextField("Heading", text: $draft.title)
                TextField("Description", text: $draft.subtitle, axis: .vertical)
                TextField("Image description for accessibility", text: $draft.imageDescription, axis: .vertical)
                Text("For a poster with text already included, leave Heading and Description empty.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Toggle("Show on Home when published", isOn: $draft.isEnabled)
                NavigationLink("Preview") { BannerPreviewScreen(banner: draft, imageData: imageData) }
                Button("Save Draft on This Device") { save(publish: false) }
                Button("Publish on This Device") { confirmPublish = true }
            } footer: {
                Text("Local prototype: other members will not receive this banner. Saving as draft removes this slot from Home until it is published again.")
            }
            Section {
                Button("Remove Banner", role: .destructive) { confirmRemove = true }
            }
        }
        .navigationTitle("Edit \(draft.slot.title)")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.jpeg, .png]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= 20 * 1024 * 1024 else { throw BannerStoreError.tooLarge }
                let data = try Data(contentsOf: url)
                guard UIImage(data: data) != nil else { throw BannerStoreError.invalidImage }
                imageData = data
            } catch { errorMessage = error.localizedDescription }
        }
        .confirmationDialog("Publish this banner on this device?", isPresented: $confirmPublish, titleVisibility: .visible) {
            Button("Publish Locally") { save(publish: true) }
        } message: { Text("This replaces the saved version for this slot. It does not send anything to other members.") }
        .confirmationDialog("Remove this banner?", isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                do { try model.remove(draft.slot); dismiss() }
                catch { errorMessage = error.localizedDescription }
            }
        }
        .alert("Could Not Save", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func save(publish: Bool) {
        do { try model.save(draft, imageData: imageData, publish: publish); dismiss() }
        catch { errorMessage = error.localizedDescription }
    }
}
