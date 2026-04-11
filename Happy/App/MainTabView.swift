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

            ActivityFeedView()
                .tabItem { Label("Activity", systemImage: "bell") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
                .tag(4)
        }
        .tint(.happyGreen)
    }
}

#Preview {
    MainTabView()
        .environmentObject({
            let s = AppState()
            s.createProfile(name: "Alex S.", handicap: 12.0, industry: "Tech", pace: .fast, homeCourse: "Bethpage")
            return s
        }())
        .environmentObject(AuthManager())
}
