//
//  KofCBellevueApp.swift
//  KofCBellevue
//
//  Created by Shebin on 11/5/26.
//

import SwiftUI

@main
struct KofCBellevueApp: App {
    @StateObject private var bannerModel = BannerManagementViewModel(
        repository: LocalBannerRepository()
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bannerModel)
                .task {
                    LocalMinutesStorage.refreshBanner(
                        in: bannerModel
                    )
                }
        }
    }
}

