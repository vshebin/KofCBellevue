//
//  SettingsScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/6/26.
//

import SwiftUI

struct SettingsScreen: View {
    @Binding var appearance: String
    @AppStorage("demoNotifications") private var notifications = true
    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $appearance) {
                    Text("System").tag("System")
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }
            }
            Section {
                Toggle("Updates (demo preference)", isOn: $notifications)
            } header: { Text("Notifications") } footer: {
                Text("Saves your preference on this device. Push notifications are not connected.")
            }
            Section("Account") {
                NavigationLink { ProfileScreen() } label: { Label("Profile", systemImage: "person.crop.circle") }
            }
            Section("Information") {
                NavigationLink("About KofC Bellevue") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("KofC Bellevue").font(.largeTitle.bold())
                            Text("A community communication app concept based on your sketches.")
                            Text("Version 0.1 • UI prototype").foregroundStyle(.secondary)
                            Text("No real member data, authentication, group permissions, finance, or messaging backend is included.")
                        }.padding()
                    }.navigationTitle("About")
                }
            }
            Section("Notifications") {
                NavigationLink("Notification preferences") {
                    NotificationSettingsScreen()
                }
            }
        }.navigationTitle("Settings")
    }
}
