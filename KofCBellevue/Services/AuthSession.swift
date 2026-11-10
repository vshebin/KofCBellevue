//
//  AuthSession.swift
//  KofCBellevue
//
//  Created by Shebin on 11/9/26.
//

import Foundation
import Combine
import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore

@MainActor
final class AuthSession: ObservableObject {
    @Published private(set) var user: FirebaseAuth.User?
    @Published private(set) var isRestoringSession = true
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?
    @Published private(set) var profileImage: UIImage?
    @Published private(set) var profileTabImage: UIImage?

    // Changes only when the photo changes, not on every view update.
    @Published private(set) var profilePhotoVersion = UUID()


    private var auth: Auth?
    private var listener: AuthStateDidChangeListenerHandle?

    func start() {
        guard listener == nil else { return }

        let auth = Auth.auth()
        self.auth = auth

        listener = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                guard let self else { return }

                let accountChanged = self.user?.uid != user?.uid

                self.user = user

                if accountChanged {
                    if let userID = user?.uid {
                        self.restoreProfileImage(for: userID)
                    } else {
                        self.applyProfileImage(nil)
                    }
                }

                self.isRestoringSession = false
            }
        }
    }

    func signIn(email: String, password: String) async {
        guard !isBusy, let auth else { return }

        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Enter your email address and password."
            return
        }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            _ = try await auth.signIn(
                withEmail: email,
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithGoogle() async {
        guard !isBusy, let auth else { return }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Google sign-in configuration is missing."
            return
        }

        guard let presenter = Self.presentingViewController() else {
            errorMessage = "Unable to open Google sign-in."
            return
        }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            GIDSignIn.sharedInstance.configuration =
                GIDConfiguration(clientID: clientID)

            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presenter
            )

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google did not return an identity token."
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            _ = try await auth.signIn(with: credential)
        } catch {
            let nsError = error as NSError

            if nsError.domain == kGIDSignInErrorDomain,
               nsError.code == GIDSignInError.Code.canceled.rawValue {
                return
            }

            errorMessage = error.localizedDescription
        }
    }
    
    func signUp(
        email: String,
        password: String,
        confirmPassword: String
    ) async {
        guard !isBusy else { return }

        guard let auth else {
            errorMessage = "Authentication is not ready. Please try again."
            return
        }

        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !email.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {
            errorMessage = "Complete all fields."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        // First, create the Authentication account.
        let result: AuthDataResult

        do {
            result = try await auth.createUser(
                withEmail: email,
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        // Then, create the matching Firestore profile.
        let newUser = result.user

        do {
            try await Firestore.firestore()
                .collection("users")
                .document(newUser.uid)
                .setData([
                    "uid": newUser.uid,
                    "email": newUser.email ?? email,
                    "createdAt": FieldValue.serverTimestamp()
                ])
        } catch {
            // The Authentication account exists even if this write fails.
            // Sign out rather than treating registration as complete.
            try? auth.signOut()
            user = nil

            errorMessage = """
            Your login account was created, but your profile could not be saved.
            Do not register again with the same email.
            Database error: \(error.localizedDescription)
            """
        }
    }

    func signOut() {
        guard !isBusy, let auth else { return }

        errorMessage = nil

        do {
            try auth.signOut()
            GIDSignIn.sharedInstance.signOut()

            applyProfileImage(nil)
            user = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func setProfileImage(_ image: UIImage, for userID: String) {
        guard user?.uid == userID else { return }

        do {
            let url = try profilePhotoURL(for: userID)

            guard let data = image.jpegData(compressionQuality: 0.85) else {
                throw ProfilePhotoError.encodingFailed
            }

            try data.write(to: url, options: .atomic)

            // Keep this local photo out of normal device backups.
            var fileURL = url
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try fileURL.setResourceValues(values)

            applyProfileImage(image)
        } catch {
            errorMessage = "Unable to save profile photo: \(error.localizedDescription)"
        }
    }
    
    private enum ProfilePhotoError: Error {
        case encodingFailed
    }

    private static func presentingViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        guard var controller = scene?.windows
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            return nil
        }

        while let presented = controller.presentedViewController {
            controller = presented
        }

        return controller
    }
    
    private func profilePhotoURL(for userID: String) throws -> URL {
        let manager = FileManager.default

        let support = try manager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let folder = support.appendingPathComponent(
            "ProfilePhotos",
            isDirectory: true
        )

        try manager.createDirectory(
            at: folder,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Encode the UID into a safe, deterministic filename.
        let filename = userID.utf8
            .map { String(format: "%02x", Int($0)) }
            .joined()

        return folder.appendingPathComponent(filename + ".jpg")
    }

    private func restoreProfileImage(for userID: String) {
        do {
            let url = try profilePhotoURL(for: userID)

            guard FileManager.default.fileExists(atPath: url.path) else {
                applyProfileImage(nil)
                return
            }

            let data = try Data(contentsOf: url)

            guard let image = UIImage(data: data) else {
                applyProfileImage(nil)
                return
            }

            applyProfileImage(image)
        } catch {
            applyProfileImage(nil)
            errorMessage = "Unable to load saved profile photo."
        }
    }

    private func applyProfileImage(_ image: UIImage?) {
        profileImage = image
        profileTabImage = image.flatMap { makeTabImage(from: $0) }
        profilePhotoVersion = UUID()
    }

    private func makeTabImage(from image: UIImage) -> UIImage? {
        guard image.size.width > 0,
              image.size.height > 0 else {
            return nil
        }

        let size = CGSize(width: 28, height: 28)

        return UIGraphicsImageRenderer(size: size).image { _ in
            let bounds = CGRect(origin: .zero, size: size)
            UIBezierPath(ovalIn: bounds).addClip()

            let scale = max(
                size.width / image.size.width,
                size.height / image.size.height
            )

            let drawnSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )

            image.draw(
                in: CGRect(
                    x: (size.width - drawnSize.width) / 2,
                    y: (size.height - drawnSize.height) / 2,
                    width: drawnSize.width,
                    height: drawnSize.height
                )
            )
        }
        .withRenderingMode(.alwaysOriginal)
    }
}
