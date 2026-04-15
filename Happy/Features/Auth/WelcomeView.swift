import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var appear = false
    @State private var showEmailAuth = false
    @State private var showDevLogin = false

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            // Background glows
            Circle()
                .fill(Color.happyGreenMid.opacity(0.07))
                .frame(width: 560, height: 560)
                .offset(x: 120, y: -220)
                .blur(radius: 90)
            Circle()
                .fill(Color.happyAccent.opacity(0.05))
                .frame(width: 440, height: 440)
                .offset(x: -160, y: 240)
                .blur(radius: 80)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    // Badge
                    HappyBadge(text: "Tri-State & South FL Beta · Invite Only", showDot: true)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 18)
                        .animation(HappyAnimation.pageLoad.delay(0.0), value: appear)
                        .padding(.bottom, 24)

                    // Eyebrow
                    Text("Where your round becomes your network")
                        .font(HappyFont.bodyMedium(size: 12))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundColor(.happyGreenLight)
                        .multilineTextAlignment(.center)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 18)
                        .animation(HappyAnimation.pageLoad.delay(0.09), value: appear)
                        .padding(.bottom, HappySpacing.md)

                    // Hero headline
                    VStack(spacing: 0) {
                        Text("Golf on your")
                            .font(HappyFont.displayHeadline(size: 44))
                            .foregroundColor(.happyGreen)
                            .lineSpacing(2)
                        Text("terms.")
                            .font(HappyFont.displayHeadlineItalic(size: 44))
                            .foregroundColor(.happyGreenLight)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(HappyAnimation.pageLoad.delay(0.18), value: appear)
                    .padding(.bottom, HappySpacing.sm)

                    // Tagline
                    Text("No randoms. No awkward pairings. Ever.")
                        .font(HappyFont.displayHeadlineItalic(size: 17))
                        .foregroundColor(.happySand)
                        .multilineTextAlignment(.center)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 16)
                        .animation(HappyAnimation.pageLoad.delay(0.27), value: appear)
                        .padding(.bottom, 24)

                    // Description
                    Text("Golf is the best networking you're not using. Play with people who match your skill, pace, and vibe — and build a reputation that opens better doors.")
                        .font(HappyFont.bodyLight(size: 15))
                        .foregroundColor(.happyMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 28)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 16)
                        .animation(HappyAnimation.pageLoad.delay(0.36), value: appear)
                        .padding(.bottom, 32)

                    // Auth CTAs
                    VStack(spacing: HappySpacing.sm) {
                        // Sign in with Apple
                        Button {
                            authManager.startAppleSignIn()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Sign in with Apple")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.black)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .opacity(appear ? 1 : 0)
                        .animation(HappyAnimation.pageLoad.delay(0.45), value: appear)

                        // Divider
                        HStack(spacing: HappySpacing.sm) {
                            Rectangle().fill(Color.happySandLight).frame(height: 1)
                            Text("or").font(HappyFont.metaSmall).foregroundColor(.happyMuted)
                            Rectangle().fill(Color.happySandLight).frame(height: 1)
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 16)
                        .animation(HappyAnimation.pageLoad.delay(0.48), value: appear)

                        // Email magic link
                        Button {
                            showEmailAuth = true
                        } label: {
                            Text("Continue with Email →")
                                .font(HappyFont.buttonLabel)
                                .tracking(0.8)
                                .foregroundColor(.happyGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .overlay(Capsule().stroke(Color.happySand, lineWidth: 1))
                        }
                        .buttonStyle(HappyButtonPressStyle())
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 16)
                        .animation(HappyAnimation.pageLoad.delay(0.51), value: appear)

                        Text("Tri-State area & South Florida beta · Members approved individually")
                            .font(.system(size: 11))
                            .foregroundColor(.happyMuted)
                            .tracking(0.3)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                            .opacity(appear ? 1 : 0)
                            .animation(HappyAnimation.pageLoad.delay(0.54), value: appear)
                    }
                    .padding(.horizontal, HappySpacing.xl)

                    Spacer().frame(height: 32)

                    // Footer logo
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: HappyRadius.icon)
                                .fill(Color.happyGreen)
                                .frame(width: 22, height: 22)
                            Text("⛳")
                                .font(.system(size: 12))
                        }
                        Text("Happy")
                            .font(HappyFont.displayMedium(size: 15))
                            .foregroundColor(.happyGreen)
                        Text("·")
                            .foregroundColor(.happySand)
                        Text("happy.golf")
                            .font(HappyFont.metaTiny)
                            .foregroundColor(.happyMuted)
                    }
                    .opacity(appear ? 0.6 : 0)
                    .animation(HappyAnimation.pageLoad.delay(0.54), value: appear)
                    .padding(.bottom, HappySpacing.xs)

                    #if DEBUG
                    Button("Dev Login") { showDevLogin = true }
                        .font(.system(size: 11))
                        .foregroundColor(.happyMuted.opacity(0.4))
                        .padding(.bottom, HappySpacing.md)
                    #endif

                    Spacer().frame(height: 20)
                }
                .frame(maxWidth: .infinity)
                .containerRelativeFrame(.horizontal)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appear = true }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView()
        }
        .sheet(isPresented: $showDevLogin) {
            DevLoginView()
        }
        .overlay(alignment: .top) {
            if let error = authManager.error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(8)
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            if authManager.isLoading {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.happyWhite)
                        .scaleEffect(1.4)
                }
            }
        }
    }

}

#Preview {
    WelcomeView()
        .environmentObject(AuthManager())
        .environmentObject(AppState())
}
