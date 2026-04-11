import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if !authManager.isReady {
                SplashView()
            } else if authManager.isSignedIn {
                if appState.isOnboarded {
                    MainTabView()
                } else {
                    ProfileSetupView()
                }
            } else {
                WelcomeView()
            }
        }
        .animation(.easeOut(duration: 0.4), value: authManager.isReady)
        .animation(.easeOut(duration: 0.4), value: authManager.isSignedIn)
        .animation(.easeOut(duration: 0.3), value: appState.isOnboarded)
    }
}
