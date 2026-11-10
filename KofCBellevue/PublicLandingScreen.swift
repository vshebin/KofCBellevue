//
//  Untitled.swift
//  KofCBellevue
//
//  Created by Shebin on 11/9/26.
//

import SwiftUI

struct PublicLandingScreen: View {
    let bannerAssetName: String

    @State private var showLoginRequired = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(bannerAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                        .accessibilityLabel("KofC Bellevue banner")

                    Text("Welcome to Sacred Heart Knights of Columbus")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text("Log in to access member features.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    NavigationLink {
                        LoginScreen()
                    } label: {
                        Text("Login")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Sacred Heart Knights")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                lockedTabBar
            }
            .alert(
                "Login required",
                isPresented: $showLoginRequired
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please log in first to access member features.")
            }
        }
    }

    private var lockedTabBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 0) {
                lockedTab(
                    title: "Home",
                    symbol: "house.fill"
                )

                lockedTab(
                    title: "Messages",
                    symbol: "bubble.left.and.bubble.right"
                )

                lockedTab(
                    title: "Settings",
                    symbol: "gearshape.fill"
                )

                lockedTab(
                    title: "Profile",
                    symbol: "person.crop.circle"
                )
            }
            .padding(.vertical, 8)
        }
        .background(.regularMaterial)
    }

    private func lockedTab(
        title: String,
        symbol: String
    ) -> some View {
        Button {
            showLoginRequired = true
        } label: {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 22))

                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Login required")
    }
}
