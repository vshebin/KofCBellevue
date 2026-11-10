//
//  HomeScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/6/26.
//

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject private var bannerModel: BannerManagementViewModel
    
    var openMessages: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HomeBannerCarousel(
                    banners: bannerModel.visibleBanners,
                    interval: 5
                )
                
                messagesSection
        
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .background(
            Color(uiColor: .systemGroupedBackground)
        )
    }
    
    private var messagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Messages")
                    .font(.title2.bold())
                
                Spacer()
                
                Button(
                    "View all",
                    action: openMessages
                )
            }
            
            EmptyPanel(
                symbol: "bubble.left.and.bubble.right",
                title: "No new messages",
                subtitle: "Updates from your council will appear here."
            )
        }
    }
}

#Preview("Home — Banners") {
    HomeBannerPreviewHost()
}

private struct HomeBannerPreviewHost: View {
    @StateObject private var bannerModel = BannerManagementViewModel(
        repository: LocalBannerRepository()
    )

    var body: some View {
        HomeScreen(openMessages: {})
            .environmentObject(bannerModel)
    }
}

#Preview("Home — Banners") {
    NavigationStack {
        HomeScreen(openMessages: {})
            .navigationTitle("Sacred Heart Knights")
    }
    .environmentObject(
        BannerManagementViewModel(
            repository: LocalBannerRepository()
        )
    )
}
