import SwiftUI
struct MessagesScreen: View {
    var database = DatabaseRecipientRepository()
    @State private var showNewMessage = false
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 42)).foregroundStyle(.secondary)
            Text("No conversations yet").font(.headline)
            Text("Start a message using your church directory or phone contacts.").foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer()
        }
        .padding(24).frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Messages")
        .safeAreaInset(edge: .bottom) {
            Button { showNewMessage = true } label: {
                Label("New message", systemImage: "plus.circle.fill").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
            }.buttonStyle(.borderedProminent).padding().background(.regularMaterial)
        }
        .sheet(isPresented: $showNewMessage) { RecipientPickerScreen(database: database) }
    }
}
