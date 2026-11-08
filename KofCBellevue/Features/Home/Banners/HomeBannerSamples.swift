//
//  HomeBannerSamples.swift
//  KofCBellevue
//
//  Created by Shebin on 11/7/26.
//

enum HomeBannerSamples {
    static let items: [HomeBanner] = [
        HomeBanner(
            id: "welcome",
            title: "Welcome, brothers",
            subtitle: "Stay connected with your Bellevue community.",
            systemImage: "person.3.fill",
            imageName: "ChurchBanner"
        ),

        HomeBanner(
            id: "service",
            title: "Serve together",
            subtitle: "Find ways to give your time and support.",
            systemImage: "hands.sparkles.fill"
        ),

        HomeBanner(
            id: "updates",
            title: "Stay informed",
            subtitle: "Council updates, all in one place.",
            systemImage: "megaphone.fill"
        )
    ]
}
