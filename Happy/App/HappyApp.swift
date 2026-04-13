import SwiftUI

@main
struct HappyApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authManager)
                .onOpenURL { url in
                    Task { await authManager.handleDeepLink(url) }
                }
        }
    }
}
