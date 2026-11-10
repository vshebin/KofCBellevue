//
//  SettingsScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/6/26.
//

import SwiftUI

struct SettingsScreen: View {
    @Binding var appearance: String

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $appearance) {
                    Text("System").tag("System")
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }
            }

            Section("Notifications") {
                NavigationLink("Notification preferences") {
                    NotificationSettingsScreen()
                }
            }

            Section("Information") {
                NavigationLink("About KofC Bellevue") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("KofC Bellevue")
                                .font(.largeTitle.bold())

                            Text(
                                "A community communication app for KofC Bellevue."
                            )

                            Text("Version 0.1 • In development")
                                .foregroundStyle(.secondary)

                            Text(
                                """
                                Features are under development. \
                                Some screens may display sample \
                                content or local-only preferences.
                                """
                            )
                        }
                        .padding()
                    }
                    .navigationTitle("About")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
