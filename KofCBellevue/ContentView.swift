import SwiftUI
import UIKit

// Main signed-in interface: tabs, side menu, and feature sheets.
@MainActor
struct ContentView: View {
    @AppStorage("appearance") private var appearance = "System"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var bannerModel: BannerManagementViewModel
    @EnvironmentObject private var session: AuthSession
    @State private var tab = 0
    @State private var showMenu = false
    @State private var showNotifications = false
    @State private var minutesRoute: MinutesRoute?
    @State private var showBannerManagement = false
    private let accent = Color(red: 0.14, green: 0.28, blue: 0.47)

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                mainTabs
                    .allowsHitTesting(!showMenu)
                    .accessibilityHidden(showMenu)

                if showMenu {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { setMenu(false) }
                        .accessibilityLabel("Close menu")
                        .accessibilityAddTraits(.isButton)
                        .transition(.opacity)

                    drawer
                        .frame(width: min(320, geometry.size.width * 0.86))
                        .frame(maxHeight: .infinity)
                        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
                        .shadow(color: .black.opacity(0.18), radius: 16, x: 5)
                        .transition(.move(edge: .leading))
                        .gesture(
                            DragGesture(minimumDistance: 25)
                                .onEnded { value in
                                    if value.translation.width < -60 &&
                                        abs(value.translation.width) > abs(value.translation.height) {
                                        setMenu(false)
                                    }
                                }
                        )
                        .accessibilityAction(.escape) { setMenu(false) }
                }
            }
        }
        .tint(accent)
        .preferredColorScheme(appearance == "System" ? nil : (appearance == "Dark" ? .dark : .light))
        .sheet(isPresented: $showNotifications) {
            NavigationStack {
                EmptyPanel(
                    symbol: "bell",
                    title: "You're all caught up",
                    subtitle: "New church notifications will appear here."
                )
                .padding()
                .navigationTitle("Notifications")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showNotifications = false }
                    }
                }
            }
        }
        .sheet(item: $minutesRoute) { route in
            NavigationStack {
                Group {
                    switch route {
                    case .publish:
                        PublishMinutesScreen()

                    case .latest:
                        PublishedMinutesScreen()

                    case .history:
                        MinutesPlaceholderScreen(route: route)
                    }
                }
                .toolbar {
                    // PublishedMinutesScreen already has its own Done button.
                    if route != .latest {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                minutesRoute = nil
                            }
                        }
                    }
                }
            }
            .environmentObject(bannerModel)
        }
        .sheet(isPresented: $showBannerManagement) {
            NavigationStack {
                ManageBannersScreen()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showBannerManagement = false
                            }
                        }
                    }
            }
            .environmentObject(bannerModel)
        }
    }

    private var mainTabs: some View {
        TabView(selection: $tab) {
            NavigationStack {
                HomeScreen(openMessages: { tab = 1 })
                    .navigationTitle("Sacred Heart Knights")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button { setMenu(true) } label: {
                                Image(systemName: "line.3.horizontal")
                            }
                            .accessibilityLabel("Open menu")
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button { showNotifications = true } label: {
                                Image(systemName: "bell.badge")
                            }
                            .accessibilityLabel("Notifications")
                        }
                    }
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            NavigationStack { MessagesScreen() }
                .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right") }
                .tag(1)

            NavigationStack { SettingsScreen(appearance: $appearance) }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)

            NavigationStack { ProfileScreen() }
                .tabItem {
                    Label {
                        Text("Profile")
                    } icon: {
                        if let image = session.profileTabImage {
                            Image(uiImage: image)
                                .renderingMode(.original)
                        } else {
                            Image(systemName: "person.crop.circle")
                        }
                    }
                }
                .tag(3)
        }
        .id(session.profilePhotoVersion)
    }
    
    private var selectedMenuDestination: SideMenuDestination {
        switch tab {
        case 1:
            return .messages
            
        default:
            return .home
        }
    }

    private func handleMenuSelection(
        _ destination: SideMenuDestination
    ) {
        setMenu(false)

        switch destination {
        case .home:
            tab = 0

        case .messages:
            tab = 1

        case .latestMinutes:
            minutesRoute = .latest

        case .minutesHistory:
            minutesRoute = .history

        case .publishMinutes:
            minutesRoute = .publish
            
        case .manageBanners:
            showBannerManagement = true
        }
    }

    private var drawer: some View {
        SideMenuView(
                selectedDestination: selectedMenuDestination,
                accent: accent,
                onSelect: handleMenuSelection,
                onClose: {
                    setMenu(false)
                }
            )
        }
    
//    private var profileTabImage: UIImage? {
//        guard let image = session.profileImage,
//              image.size.width > 0,
//              image.size.height > 0 else {
//            return nil
//        }
//
//        let size = CGSize(width: 28, height: 28)
//
//        return UIGraphicsImageRenderer(size: size).image { _ in
//            let bounds = CGRect(origin: .zero, size: size)
//
//            UIBezierPath(ovalIn: bounds).addClip()
//
//            let scale = max(
//                size.width / image.size.width,
//                size.height / image.size.height
//            )
//
//            let drawnSize = CGSize(
//                width: image.size.width * scale,
//                height: image.size.height * scale
//            )
//
//            image.draw(
//                in: CGRect(
//                    x: (size.width - drawnSize.width) / 2,
//                    y: (size.height - drawnSize.height) / 2,
//                    width: drawnSize.width,
//                    height: drawnSize.height
//                )
//            )
//        }
//    }

    private func setMenu(_ visible: Bool) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            showMenu = visible
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthSession())
        .environmentObject(
            BannerManagementViewModel(
                repository: LocalBannerRepository()
            )
        )
}
