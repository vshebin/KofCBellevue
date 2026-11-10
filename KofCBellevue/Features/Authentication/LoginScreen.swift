//
//  LoginScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/9/26.
//

import SwiftUI
import GoogleSignInSwift

struct LoginScreen: View {
    @EnvironmentObject private var session: AuthSession

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Sign in to KoC Bellevue")
                    .font(.title2.bold())
                    .padding(.top, 24)

                VStack(spacing: 16) {
                    TextField("Email address", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)
                }

                if let message = session.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task {
                        await session.signIn(
                            email: email,
                            password: password
                        )
                    }
                } label: {
                    Text("Sign in")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    session.isBusy ||
                    email.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty ||
                    password.isEmpty
                )

                HStack {
                    Rectangle().frame(height: 1)
                    Text("or")
                    Rectangle().frame(height: 1)
                }
                .foregroundStyle(.secondary)

                // Google sign-in and Sign up, side by side
                HStack(spacing: 12) {
                    GoogleSignInButton {
                        Task {
                            await session.signInWithGoogle()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(session.isBusy)
                    
                    NavigationLink {
                        SignUpScreen()
                    } label: {
                        Text("Sign up")
                            .font(.subheadline.weight(.semibold))
                            .frame(minHeight: 44)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.bordered)
                    .disabled(session.isBusy)
                }

                if session.isBusy {
                    ProgressView("Signing in…")
                }
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            session.errorMessage = nil
        }
        .onDisappear {
            password = ""
        }
    }
}
