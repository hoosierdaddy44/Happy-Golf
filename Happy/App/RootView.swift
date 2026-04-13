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
                    if appState.isApproved {
                        MainTabView()
                    } else {
                        PendingApprovalView()
                    }
                } else {
                    ProfileSetupView()
                }
            } else {
                WelcomeView()
            }
        }
        .preferredColorScheme(.light)
        .animation(.easeOut(duration: 0.4), value: authManager.isReady)
        .animation(.easeOut(duration: 0.4), value: authManager.isSignedIn)
        .animation(.easeOut(duration: 0.3), value: appState.isOnboarded)
        .animation(.easeOut(duration: 0.3), value: appState.isApproved)
        .onChange(of: authManager.isSignedIn) { _, signedIn in
            if signedIn {
                let userId = authManager.session?.user.id ?? UUID()
                if authManager.devBypass { appState.devUserId = userId }
                Task { await appState.load(userId: userId) }
            }
        }
        .task {
            if authManager.isSignedIn, let userId = authManager.session?.user.id {
                await appState.load(userId: userId)
            }
        }
    }
}
