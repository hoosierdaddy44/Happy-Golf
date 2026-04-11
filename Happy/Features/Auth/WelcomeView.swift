import SwiftUI
import AuthenticationServices
import CryptoKit

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var appear = false
    @State private var showEmailAuth = false
    @State private var showDevLogin = false
    @State private var nonce: String = ""

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
                    HappyBadge(text: "NYC Beta · Invite Only", showDot: true)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 18)
                        .animation(HappyAnimation.pageLoad.delay(0.0), value: appear)
                        .padding(.bottom, 24)

                    // Eyebrow
                    Text("Golf with people you actually like")
                        .font(HappyFont.bodyMedium(size: 12))
                        .tracking(2.0)
                        .textCase(.uppercase)
                        .foregroundColor(.happyGreenLight)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 18)
                        .animation(HappyAnimation.pageLoad.delay(0.09), value: appear)
                        .padding(.bottom, HappySpacing.md)

                    // Hero headline
                    VStack(spacing: 0) {
                        Text("Doesn't that make")
                            .font(HappyFont.displayHeadline(size: 42))
                            .foregroundColor(.happyGreen)
                            .lineSpacing(2)
                        HStack(spacing: 0) {
                            Text("you ")
                                .font(HappyFont.displayHeadline(size: 42))
                                .foregroundColor(.happyGreen)
                            Text("happy?")
                                .font(HappyFont.displayHeadlineItalic(size: 42))
                                .foregroundColor(.happyGreenLight)
                        }
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
                    Text("A private network for curated golf rounds. Play with people who match your skill, pace, and vibe — and build a reputation that opens better doors.")
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
                        SignInWithAppleButton(.continue) { request in
                            nonce = randomNonceString()
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        } onCompletion: { result in
                            switch result {
                            case .success(let auth):
                                guard
                                    let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                                    let tokenData = cred.identityToken,
                                    let idToken = String(data: tokenData, encoding: .utf8)
                                else { return }
                                Task {
                                    await authManager.signInWithApple(idToken: idToken, nonce: nonce)
                                }
                            case .failure:
                                break
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 52)
                        .cornerRadius(HappyRadius.pill)

                        // Divider
                        HStack(spacing: HappySpacing.sm) {
                            Rectangle().fill(Color.happySandLight).frame(height: 1)
                            Text("or").font(HappyFont.metaSmall).foregroundColor(.happyMuted)
                            Rectangle().fill(Color.happySandLight).frame(height: 1)
                        }

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

                        Text("Limited NYC & South Florida beta · Members approved individually")
                            .font(.system(size: 11))
                            .foregroundColor(.happyMuted)
                            .tracking(0.3)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, HappySpacing.xl)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 16)
                    .animation(HappyAnimation.pageLoad.delay(0.45), value: appear)

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

    // MARK: - Apple Sign In Helpers

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthManager())
        .environmentObject(AppState())
}
