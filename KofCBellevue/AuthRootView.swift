//
//  AuthRootView.swift
//  KofCBellevue
//
//  Created by Shebin on 11/9/26.
//

import SwiftUI

struct AuthRootView<PublicBanner: View>: View {
    @EnvironmentObject private var session: AuthSession

    private let publicBanner: () -> PublicBanner

    init(
        @ViewBuilder publicBanner: @escaping () -> PublicBanner
    ) {
        self.publicBanner = publicBanner
    }

    var body: some View {
        Group {
            if session.isRestoringSession {
                ProgressView("Opening KoC Bellevue…")
            } else if session.user != nil && !session.isBusy {
                ContentView()
            } else {
                PublicLandingScreen(
                bannerAssetName: "ChurchBanner"
                    )
            }
        }
        .task {
            session.start()
        }
    }
}
