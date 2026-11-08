//
//  HomeBannerCard.swift
//  KofCBellevue
//
//  Created by Shebin on 11/7/26.
//

import SwiftUI
import UIKit

struct HomeBannerCard: View {
    let banner: BannerContent
    var imageOverride: UIImage? = nil

    private let store = BannerImageStore()

    private var hasText: Bool {
        !banner.title.isEmpty || !banner.subtitle.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if banner.slot == .welcome {
                Image(systemName: "person.3.fill")
                    .font(.largeTitle)
                    .accessibilityHidden(true)
            } else if banner.slot == .minutes {
                Image(systemName: "doc.text.fill")
                    .font(.largeTitle)
                    .accessibilityHidden(true)

                Text("MEETING MINUTES")
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
            }

            if !banner.title.isEmpty {
                Text(banner.title)
                    .font(.title2.bold())
            }

            if !banner.subtitle.isEmpty {
                Text(banner.subtitle)
                    .font(.body)
            }

            Spacer(minLength: 8)
        }
        .padding(24)
        .foregroundStyle(.white)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background {
            GeometryReader { geometry in
                bannerBackground(size: geometry.size)
            }
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 24)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [
                banner.title,
                banner.subtitle,
                banner.imageDescription
            ]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
        )
    }

    @ViewBuilder
    private func bannerBackground(size: CGSize) -> some View {
        switch banner.slot {
        case .welcome:
            // Only Banner 1 uses the church asset.
            imageBackground(
                Image("ChurchBanner"),
                size: size
            )

        case .second, .third, .fourth:
            // Uploaded banners never fall back to the church image.
            if let image = imageOverride
                ?? store.image(named: banner.imageFilename) {
                imageBackground(
                    Image(uiImage: image),
                    size: size
                )
            } else {
                // Editor/preview placeholder only.
                // Empty slots remain filtered out of Home.
                Color.gray.opacity(0.75)
                    .overlay {
                        if !hasText {
                            Image(systemName: "photo")
                                .font(.system(size: 44))
                                .foregroundStyle(.white.opacity(0.7))
                                .accessibilityHidden(true)
                        }
                    }
            }

        case .minutes:
            // Banner 5 has its own background, not the church photo.
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.18, blue: 0.34),
                    Color(red: 0.16, green: 0.34, blue: 0.53)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func imageBackground(
        _ image: Image,
        size: CGSize
    ) -> some View {
        image
            .resizable()
            .scaledToFill()
            .frame(
                width: size.width,
                height: size.height
            )
            .clipped()
            .overlay {
                if hasText {
                    LinearGradient(
                        colors: [
                            .black.opacity(0.65),
                            .black.opacity(0.12)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
    }
}
