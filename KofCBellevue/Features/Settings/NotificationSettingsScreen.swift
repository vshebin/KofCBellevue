import SwiftUI
import UserNotifications
struct NotificationSettingsScreen: View {
    @AppStorage("koc.notifications.enabled") private var enabled = false
    @AppStorage("koc.notifications.tone") private var tone = NotificationTone.defaultTone.rawValue
    @AppStorage("koc.notifications.hidePreview") private var hidePreview = false
    @State private var status = ""
    var body: some View {
        Form {
            Section {
                Toggle("App notifications preference", isOn: $enabled)
                Button("Request iOS notification permission") {
                    Task { @MainActor in
                        do {
                            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                            status = granted ? "Permission granted. No push backend is connected." : "Permission not granted. Check iPhone Settings."
                        } catch { status = error.localizedDescription }
                    }
                }
                if !status.isEmpty { Text(status).font(.footnote) }
            } header: { Text("App notifications") } footer: {
                Text("The app preference does not change iOS system settings or enable server delivery.")
            }
            Section("Sound") {
                Picker("Notification tone", selection: $tone) {
                    ForEach(NotificationTone.allCases) { option in
                        Text(option.rawValue).tag(option.rawValue).disabled(!option.isAvailable)
                    }
                }
                Text("Custom tones are disabled until gentle-bell.wav and soft-chime.wav are added to the app target. This setting does not change SMS or Mail tones.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Preview") {
                Toggle("Hide message content", isOn: $hidePreview)
            }
            Section {
                Button("Send local test notification") {
                    Task { @MainActor in
                        guard enabled else { status = "Enable the app preference first."; return }
                        let content = UNMutableNotificationContent()
                        content.title = "KoC Bellevue"
                        var example = MessageDraft()
                        example.body = "This is a local notification test."
                        content.body = hidePreview ? "You have a new message." : example.preview
                        content.sound = (NotificationTone(rawValue: tone) ?? .defaultTone).sound
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
                        do {
                            try await UNUserNotificationCenter.current().add(request)
                            status = "Test scheduled. Put the app in the background within 5 seconds to see it; iOS notification settings still apply."
                        } catch { status = error.localizedDescription }
                    }
                }
            }
        }.navigationTitle("Notifications").navigationBarTitleDisplayMode(.inline)
    }
}
