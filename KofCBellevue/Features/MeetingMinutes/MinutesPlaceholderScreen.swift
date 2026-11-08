//
//  MinutesPlaceholderScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/7/26.
//

import SwiftUI

enum MinutesRoute: String, Identifiable {
    case latest
    case history
    case publish

    var id: String { rawValue }

    var title: String {
        switch self {
        case .latest:
            return "Latest Minutes"
        case .history:
            return "Minutes History"
        case .publish:
            return "Publish Minutes"
        }
    }

    var systemImage: String {
        switch self {
        case .latest:
            return "doc.text"
        case .history:
            return "clock.arrow.circlepath"
        case .publish:
            return "square.and.pencil"
        }
    }

    var explanation: String {
        switch self {
        case .latest:
            return "The newest published meeting minutes will appear here."

        case .history:
            return """
            The latest five published meetings will appear here, \
            including the meeting shown on Home.
            """

        case .publish:
            return """
            The meeting-minutes editor, Save Draft, Preview, \
            and Publish actions will be added here.
            """
        }
    }
}

struct MinutesPlaceholderScreen: View {
    let route: MinutesRoute

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: route.systemImage)
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)

                Text(route.title)
                    .font(.title2.bold())

                Text(route.explanation)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Label(
                    "UI placeholder — no live data",
                    systemImage: "info.circle"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
