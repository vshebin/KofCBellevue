import SwiftUI

struct ManageBannersScreen: View {
    @EnvironmentObject private var model: BannerManagementViewModel
    var body: some View {
        List {
            Section {
                Text("Changes are saved on this device only. Login, permissions and shared publishing will be connected later.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Banner 1 — Default Welcome") {
                NavigationLink("Preview Default Banner") {
                    BannerPreviewScreen(banner: model.visibleBanners[0])
                }
                Label("Locked — not editable here", systemImage: "lock.fill")
                    .foregroundStyle(.secondary)
            }
            ForEach(BannerSlot.allCases.filter { $0.isEditable }) { slot in
                Section(slot.title) {
                    let banner = model.content(for: slot)
                    if let image = model.imageStore.image(named: banner.imageFilename) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 140)
                        Text(banner.isPublished ? (banner.isEnabled ? "Published locally" : "Disabled") : "Draft — hidden on Home")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("Empty — hidden on Home").foregroundStyle(.secondary)
                    }
                    NavigationLink(banner.imageFilename == nil ? "Add Banner" : "Edit / Replace Banner") {
                        EditBannerScreen(content: banner)
                    }
                }
            }
            Section("Banner 5 — Meeting Minutes") {
                if let banner = model.latestMinutesBanner, banner.isPublished {
                    NavigationLink("Preview MOM Banner") { BannerPreviewScreen(banner: banner) }
                } else {
                    Text("No published minutes connected — hidden on Home")
                        .foregroundStyle(.secondary)
                }
                Text("Managed through the meeting-minutes publishing feature, not image uploads here.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Manage Banners")
        .alert("Banner Storage", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }
}
