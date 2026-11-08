//
//  ProfileScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/6/26.
//

import SwiftUI

struct ProfileScreen: View {
    @AppStorage("demoName") private var name = "Demo Member"
    @AppStorage("demoEmail") private var email = ""
    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill").font(.system(size: 76)).foregroundStyle(.blue)
                    Text(name.isEmpty ? "Demo Member" : name).font(.title2.bold())
                    Text("Local preview profile").foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity).padding(.vertical)
            }
            Section("Profile details") {
                TextField("Name", text: $name)
                TextField("Email", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            Section("Membership — sample only") {
                LabeledContent("Council", value: "Bellevue")
                LabeledContent("Degree", value: "Not assigned")
                LabeledContent("Role", value: "Demo member")
            }
            Section { Text("Profile edits are stored only on this device. This is not a registered or signed-in account.").font(.footnote).foregroundStyle(.secondary) }
        }.navigationTitle("Profile")
    }
}

