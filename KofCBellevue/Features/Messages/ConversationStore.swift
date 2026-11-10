//
//  ConversationStore.swift
//  KofCBellevue
//
//  Created by Shebin on 11/9/26.
//

import Foundation
import Combine

struct KnightsHistoryMessage: Identifiable, Codable {
    let id: UUID
    let body: String
    let emailSubject: String?
    let channel: String
    let createdAt: Date
}

struct KnightsConversation: Identifiable, Codable {
    let id: String
    var title: String
    var messages: [KnightsHistoryMessage]

    var lastMessage: KnightsHistoryMessage? {
        messages.last
    }

    var updatedAt: Date {
        lastMessage?.createdAt ?? .distantPast
    }
}

@MainActor
final class ConversationStore: ObservableObject {
    @Published private(set) var conversations:
        [KnightsConversation] = []

    @Published var errorText: String?

    private let fileURL: URL

    init() {
        let directory = FileManager.default
            .urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            .appendingPathComponent(
                "SacredHeartMessageHistory",
                isDirectory: true
            )

        fileURL = directory
            .appendingPathComponent("conversations.json")

        load()
    }

    var sortedConversations: [KnightsConversation] {
        conversations.sorted {
            $0.updatedAt > $1.updatedAt
        }
    }

    func conversation(
        id: String
    ) -> KnightsConversation? {
        conversations.first { $0.id == id }
    }

    @discardableResult
    func recordOutgoingCopy(
        conversationID: String,
        title: String,
        body: String,
        emailSubject: String?,
        channel: String
    ) -> Bool {
        var updated = conversations

        let message = KnightsHistoryMessage(
            id: UUID(),
            body: body,
            emailSubject: emailSubject,
            channel: channel,
            createdAt: Date()
        )

        if let index = updated.firstIndex(
            where: { $0.id == conversationID }
        ) {
            updated[index].title = title
            updated[index].messages.append(message)
        } else {
            updated.append(
                KnightsConversation(
                    id: conversationID,
                    title: title,
                    messages: [message]
                )
            )
        }

        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )

            let data = try JSONEncoder().encode(updated)

            try data.write(
                to: fileURL,
                options: .atomic
            )

            conversations = updated
            return true
        } catch {
            errorText =
                "Could not save the message history: "
                + error.localizedDescription

            return false
        }
    }

    private func load() {
        guard FileManager.default.fileExists(
            atPath: fileURL.path
        ) else {
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)

            conversations = try JSONDecoder().decode(
                [KnightsConversation].self,
                from: data
            )
        } catch {
            errorText =
                "Could not load the message history: "
                + error.localizedDescription
        }
    }
}
