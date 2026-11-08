//
//  HomeBannerCarousel.swift
//  KofCBellevue
//
//  Created by Shebin on 11/7/26.
//

import SwiftUI

struct HomeBannerCarousel: View {
    let banners: [BannerContent]
    var interval: TimeInterval = 5

    @State private var page = 0
    @State private var paused = false
    @State private var showPublishedMinutes = false

    @GestureState private var dragging = false

    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled)
    private var voiceOver

    @ScaledMetric(relativeTo: .body)
    private var bannerHeight: CGFloat = 285

    var body: some View {
        if !banners.isEmpty {
            VStack(spacing: 0) {

                // All banner cards must remain inside this TabView.
                TabView(selection: $page) {
                    ForEach(
                        Array(banners.enumerated()),
                        id: \.element.id
                    ) { index, banner in
                        carouselPage(for: banner)
                            .padding(.horizontal, 4)
                            .tag(index)
                    }
                }
                .tabViewStyle(
                    .page(indexDisplayMode: .never)
                )
                .frame(height: bannerHeight)
                .simultaneousGesture(
                    DragGesture()
                        .updating($dragging) { _, value, _ in
                            value = true
                        }
                )

                if banners.count > 1 {
                    playbackControls
                }
            }
            .task(id: playbackKey) {
                guard canAutoAdvance else { return }

                do {
                    try await Task<Never, Never>.sleep(
                        for: .seconds(delay)
                    )
                } catch {
                    return
                }

                guard !Task.isCancelled,
                      canAutoAdvance else {
                    return
                }

                let next = (page + 1) % banners.count

                withAnimation(
                    reduceMotion || next == 0
                        ? nil
                        : .easeInOut(duration: 0.35)
                ) {
                    page = next
                }
            }
            .onChange(of: banners.map(\.id)) {
                page = 0
            }
            .sheet(isPresented: $showPublishedMinutes) {
                NavigationStack {
                    PublishedMinutesScreen()
                }
            }
        }
    }

    @ViewBuilder
    private func carouselPage(
        for banner: BannerContent
    ) -> some View {
        if banner.slot == .minutes {
            Button {
                showPublishedMinutes = true
            } label: {
                HomeBannerCard(banner: banner)
                    .contentShape(
                        RoundedRectangle(cornerRadius: 24)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityHint(
                "Opens the full published meeting minutes"
            )
        } else {
            HomeBannerCard(banner: banner)
        }
    }

    private var playbackControls: some View {
        HStack(spacing: 0) {
            ForEach(banners.indices, id: \.self) { index in
                Button {
                    page = index
                } label: {
                    Circle()
                        .fill(
                            page == index
                                ? Color.primary
                                : Color.secondary.opacity(0.35)
                        )
                        .frame(width: 7, height: 7)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(
                    "Banner \(index + 1) of \(banners.count)"
                )
                .accessibilityValue(
                    page == index ? "Selected" : ""
                )
            }

            Button {
                paused.toggle()
            } label: {
                Image(
                    systemName: paused
                        ? "play.fill"
                        : "pause.fill"
                )
                .frame(width: 44, height: 44)
            }
            .accessibilityLabel(
                paused ? "Resume banners" : "Pause banners"
            )
        }
        .buttonStyle(.plain)
    }

    private var delay: Double {
        interval.isFinite ? max(1, interval) : 5
    }

    private var canAutoAdvance: Bool {
        banners.count > 1 &&
        phase == .active &&
        !paused &&
        !dragging &&
        !voiceOver &&
        !showPublishedMinutes
    }

    private var playbackKey: PlaybackKey {
        PlaybackKey(
            page: page,
            ids: banners.map(\.id),
            delay: delay,
            enabled: canAutoAdvance
        )
    }

    private struct PlaybackKey: Equatable {
        let page: Int
        let ids: [Int]
        let delay: Double
        let enabled: Bool
    }
}
