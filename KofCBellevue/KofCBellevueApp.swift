//
//  KofCBellevueApp.swift
//  KofCBellevue
//
//  Created by Shebin on 11/5/26.
//

import SwiftUI
import GoogleSignIn

@main
struct KofCBellevueApp: App {
    @UIApplicationDelegateAdaptor(FirebaseAppDelegate.self)
    private var firebaseDelegate

    @StateObject private var session = AuthSession()

    @StateObject private var bannerModel = BannerManagementViewModel(
        repository: LocalBannerRepository()
    )

    var body: some Scene {
        WindowGroup {
            AuthRootView {
                publicBanner
            }
            .environmentObject(session)
            .environmentObject(bannerModel)
            .onOpenURL { url in
                _ = GIDSignIn.sharedInstance.handle(url)
            }
        }
    }

    private var publicBanner: some View {
        // Temporary UI: replace with your existing first-banner view.
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.blue.opacity(0.12))
            .frame(height: 220)
            .overlay {
                Text("KoC Bellevue")
                    .font(.title.bold())
            }
            .accessibilityLabel("KoC Bellevue public banner")
    }
}
