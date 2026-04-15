import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0

    private var pendingBadge: Int { appState.pendingRequestsForHost.count }

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoveryView()
                .tabItem { Label("Discover", systemImage: "magnifyingglass") }
                .tag(0)

            HostRoundView()
                .tabItem { Label("Host", systemImage: "plus.circle.fill") }
                .tag(1)

            MyRoundsView()
                .tabItem { Label("My Rounds", systemImage: "calendar") }
                .badge(pendingBadge > 0 ? pendingBadge : 0)
                .tag(2)

            GroupsView()
                .tabItem { Label("Groups", systemImage: "person.3.fill") }
                .tag(3)

            ActivityFeedView()
                .tabItem { Label("Activity", systemImage: "bell") }
                .tag(4)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
                .tag(5)
        }
        .tint(.happyGreen)
        .sheet(item: Binding(
            get: { appState.pendingRatingPrompts.first },
            set: { if $0 == nil, let first = appState.pendingRatingPrompts.first { appState.dismissRatingPrompt(for: first.id) } }
        )) { teeTime in
            RatingPromptSheet(teeTime: teeTime).environmentObject(appState)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject({
            let s = AppState()
            s.currentUser = User.jamesK
            s.isOnboarded = true
            return s
        }())
        .environmentObject(AuthManager())
}
