//
//  ProfileScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/6/26.
//

import SwiftUI
import PhotosUI
import UIKit
import FirebaseAuth
import FirebaseFirestore

@MainActor
struct ProfileScreen: View {
    @EnvironmentObject private var session: AuthSession

    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var isLoadingProfile = false
    @State private var profileError: String?
    @State private var photoError: String?


    var body: some View {
        Form {
            Section {
                VStack(spacing: 14) {
                    Button {
                        showPhotoPicker = true
                    } label: {
                        VStack(spacing: 10) {
                            avatar

                            Text(
                                session.profileImage == nil
                                    ? "Choose profile photo"
                                    : "Change profile photo"
                            )
                            .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(session.user == nil)

                    Text("My profile")
                        .font(.title2.bold())

                    Text(
                        "Photo is saved on this device and restored when you sign in."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                    if let photoError {
                        Text(photoError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section {
                Button(role: .destructive) {
                    session.signOut()
                } label: {
                    HStack(spacing: 10) {
                        Image(
                            systemName:
                                "rectangle.portrait.and.arrow.right"
                        )

                        Text("Sign out")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(session.isBusy)
                .listRowBackground(Color.clear)
                .listRowInsets(
                    EdgeInsets(
                        top: 4,
                        leading: 0,
                        bottom: 4,
                        trailing: 0
                    )
                )

                if let message = session.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("Profile details") {
                if isLoadingProfile {
                    ProgressView("Loading profile…")
                } else if let profileError {
                    Text(profileError)
                        .font(.footnote)
                        .foregroundStyle(.red)

                    Button("Retry") {
                        Task {
                            await loadProfile(
                                userID: session.user?.uid
                            )
                        }
                    }
                } else {
                    LabeledContent("Email") {
                        Text(email.isEmpty ? "Not provided" : email)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            .textSelection(.enabled)
                    }

                    LabeledContent("Phone number") {
                        Text(
                            phoneNumber.isEmpty
                                ? "Not provided"
                                : phoneNumber
                        )
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhoto,
            matching: .images
        )
        .task(id: session.user?.uid) {
            await loadProfile(userID: session.user?.uid)
        }
        .task(id: selectedPhoto) {
            await loadSelectedPhoto()
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let image = session.profileImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 110, height: 110)
                .clipShape(Circle())
                .accessibilityLabel("Selected profile photo")
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .foregroundStyle(.blue)
                .accessibilityLabel("Choose profile photo")
        }
    }

    @MainActor
    private func loadProfile(userID: String?) async {
        email = ""
        phoneNumber = ""
        profileError = nil
        isLoadingProfile = false

        guard let userID else { return }

        isLoadingProfile = true

        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(userID)
                .getDocument()

            guard !Task.isCancelled,
                  session.user?.uid == userID else {
                return
            }

            guard let data = snapshot.data() else {
                profileError = """
                No profile document exists for this account.
                """
                isLoadingProfile = false
                return
            }

            email = data["email"] as? String ?? ""
            phoneNumber = data["phoneNumber"] as? String ?? ""
            isLoadingProfile = false
        } catch {
            guard !Task.isCancelled,
                  session.user?.uid == userID else {
                return
            }

            profileError = error.localizedDescription
            isLoadingProfile = false
        }
    }

    @MainActor
    private func loadSelectedPhoto() async {
        guard let selectedPhoto,
              let userID = session.user?.uid else {
            return
        }

        photoError = nil

        do {
            guard let data = try await selectedPhoto.loadTransferable(
                type: Data.self
            ) else {
                throw PhotoLoadingError.invalidImage
            }

            guard !Task.isCancelled,
                  session.user?.uid == userID else {
                return
            }

            guard let image = UIImage(data: data) else {
                throw PhotoLoadingError.invalidImage
            }

            // Reduce the image retained in memory.
            let size = CGSize(width: 320, height: 320)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1

            let thumbnail = UIGraphicsImageRenderer(
                size: size,
                format: format
            ).image { _ in
                let scale = max(
                    size.width / image.size.width,
                    size.height / image.size.height
                )

                let drawnSize = CGSize(
                    width: image.size.width * scale,
                    height: image.size.height * scale
                )

                let rect = CGRect(
                    x: (size.width - drawnSize.width) / 2,
                    y: (size.height - drawnSize.height) / 2,
                    width: drawnSize.width,
                    height: drawnSize.height
                )

                image.draw(in: rect)
            }

            session.setProfileImage(thumbnail, for: userID)
        } catch {
            guard !Task.isCancelled,
                  session.user?.uid == userID else {
                return
            }

            photoError = "Unable to load that photo. Please try another."
        }
    }
}

private enum PhotoLoadingError: Error {
    case invalidImage
}
