import SwiftUI

struct MessagesScreen: View {
    var database = DatabaseRecipientRepository()

    @StateObject private var history = ConversationStore()
    @State private var showNewMessage = false

    var body: some View {
        Group {
            if history.conversations.isEmpty {
                emptyState
            } else {
                conversationList
            }
        }
        .navigationTitle("Messages")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewMessage = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("New message")
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                showNewMessage = true
            } label: {
                Label(
                    "New message",
                    systemImage: "plus.circle.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .background(.regularMaterial)
        }
        .sheet(isPresented: $showNewMessage) {
            NavigationStack {
                ComposeMessageScreen(database: database)
            }
            .environmentObject(history)
        }
        .alert(
            "Message history",
            isPresented: Binding(
                get: { history.errorText != nil },
                set: { presented in
                    if !presented {
                        history.errorText = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                history.errorText = nil
            }
        } message: {
            Text(history.errorText ?? "")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(
                systemName: "bubble.left.and.bubble.right"
            )
            .font(.system(size: 42))
            .foregroundStyle(.secondary)

            Text("No conversations yet")
                .font(.headline)

            Text(
                "Your saved outgoing messages will appear here."
            )
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            Color(uiColor: .systemGroupedBackground)
        )
    }

    private var conversationList: some View {
        List(history.sortedConversations) { conversation in
            NavigationLink {
                ConversationDetailScreen(
                    conversationID: conversation.id
                )
                .environmentObject(history)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(
                        systemName:
                            conversation.id.hasPrefix("group:")
                            ? "person.3.fill"
                            : "person.crop.circle.fill"
                    )
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
                    .frame(width: 42)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(conversation.title)
                                .font(.headline)
                                .lineLimit(1)

                            Spacer()

                            if let last = conversation.lastMessage {
                                Text(
                                    last.createdAt,
                                    format: .dateTime
                                        .month(.abbreviated)
                                        .day()
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }

                        Text(
                            conversation.lastMessage?.body ?? ""
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.plain)
    }
}
