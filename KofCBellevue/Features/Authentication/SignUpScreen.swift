//
//  SignUpScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/9/26.
//

import SwiftUI

struct SignUpScreen: View {
    @EnvironmentObject private var session: AuthSession

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var hasEmptyFields: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create your account")
                    .font(.title2.bold())
                    .padding(.top, 24)

                Text("Register with your email address and a password.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 16) {
                    TextField("Email address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .disabled(session.isBusy)

                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)
                        .disabled(session.isBusy)

                    SecureField(
                        "Confirm password",
                        text: $confirmPassword
                    )
                    .textContentType(.newPassword)
                    .textFieldStyle(.roundedBorder)
                    .disabled(session.isBusy)
                }

                if let message = session.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                }

                Button {
                    Task {
                        await session.signUp(
                            email: email,
                            password: password,
                            confirmPassword: confirmPassword
                        )
                    }
                } label: {
                    Text("Create account")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(session.isBusy || hasEmptyFields)

                if session.isBusy {
                    ProgressView("Creating your account…")
                }
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Sign up")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            session.errorMessage = nil
        }
        .onDisappear {
            password = ""
            confirmPassword = ""
        }
    }
}
