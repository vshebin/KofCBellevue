//
//  ConversationDetailScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/9/26.
//

import SwiftUI

struct ConversationDetailScreen: View {
    @EnvironmentObject private var history: ConversationStore

    let conversationID: String

    private var conversation: KnightsConversation? {
        history.conversation(id: conversationID)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .trailing, spacing: 16) {
                ForEach(conversation?.messages ?? []) { message in
                    VStack(alignment: .trailing, spacing: 6) {
                        VStack(alignment: .leading, spacing: 8) {
                            if let subject = message.emailSubject,
                               !subject.isEmpty {
                                Text(subject)
                                    .font(.headline)
                            }

                            Text(message.body)
                                .textSelection(.enabled)
                        }
                        .padding(12)
                        .background(
                            Color.accentColor.opacity(0.12)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )

                        Text(
                            "\(message.channel) • Outgoing copy"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Text(
                            message.createdAt,
                            format: .dateTime
                                .month(.abbreviated)
                                .day()
                                .hour()
                                .minute()
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .trailing
                    )
                }
            }
            .padding()
        }
        .navigationTitle(
            conversation?.title ?? "Conversation"
        )
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Text(
                """
                Saved outgoing copies only. Replies and edits \
                made in the SMS or email composer are not synced here.
                """
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
        }
    }
}
