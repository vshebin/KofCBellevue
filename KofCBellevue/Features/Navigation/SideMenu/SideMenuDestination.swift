//
//  SideMenuDestination.swift
//  KofCBellevue
//
//  Created by Shebin on 11/7/26.
//

import Foundation

enum SideMenuDestination: String, Identifiable, CaseIterable {
    case home
    case messages
    case latestMinutes
    case minutesHistory
    case publishMinutes
    case manageBanners


    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .messages:
            return "Messages"
        case .latestMinutes:
            return "Latest Minutes"
        case .minutesHistory:
            return "Minutes History"
        case .publishMinutes:
            return "Publish Minutes"
        case .manageBanners:
            return "Manage Banners"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .messages:
            return "bubble.left.and.bubble.right"
        case .latestMinutes:
            return "doc.text"
        case .minutesHistory:
            return "clock.arrow.circlepath"
        case .publishMinutes:
            return "square.and.pencil"
        case .manageBanners:
            return "photo.on.rectangle.angled"
        }
    }

    var tabIndex: Int? {
        switch self {
        case .home:
            return 0
        case .messages:
            return 1
        case .latestMinutes, .minutesHistory, .publishMinutes, .manageBanners:
            return nil
        }
    }

    static let mainItems: [SideMenuDestination] = [
        .home,
        .messages
    ]

    static let minutesItems: [SideMenuDestination] = [
        .latestMinutes,
        .minutesHistory,
        .publishMinutes
    ]

    static let managementItems: [SideMenuDestination] = [
        .manageBanners
    ]
}
