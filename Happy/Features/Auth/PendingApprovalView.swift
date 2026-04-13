import SwiftUI

struct PendingApprovalView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: AuthManager
    @State private var isChecking = false

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: HappySpacing.xl) {
                    Text("⛳")
                        .font(.system(size: 64))

                    VStack(spacing: HappySpacing.sm) {
                        HappySectionLabel(text: "Happy Golf")
                        Text("You're on\nthe list.")
                            .font(HappyFont.displayHeadline(size: 44))
                            .foregroundColor(.happyGreen)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }

                    Text("Your application is under review. We personally approve every member — you'll hear from us soon.")
                        .font(HappyFont.bodyLight(size: 15))
                        .foregroundColor(.happyMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, HappySpacing.xxl)

                    VStack(spacing: HappySpacing.sm) {
                        HappyPrimaryButton(title: isChecking ? "Checking..." : "Check Status", fullWidth: true) {
                            Task {
                                isChecking = true
                                await appState.checkApproval()
                                isChecking = false
                            }
                        }
                        .disabled(isChecking)
                        .opacity(isChecking ? 0.6 : 1)

                        HappyOutlineButton(title: "Sign Out", fullWidth: true) {
                            Task { await authManager.signOut() }
                        }
                    }
                    .padding(.horizontal, HappySpacing.xl)
                }

                Spacer()

                Text("joinhappy.golf")
                    .font(HappyFont.metaTiny)
                    .foregroundColor(.happySand)
                    .padding(.bottom, HappySpacing.xl)
            }
        }
    }
}

#Preview {
    PendingApprovalView()
        .environmentObject({
            let s = AppState()
            s.currentUser = User.jamesK
            s.isOnboarded = true
            return s
        }())
        .environmentObject(AuthManager())
}
