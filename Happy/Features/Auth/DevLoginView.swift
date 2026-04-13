import SwiftUI

struct DevLoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""

    private var isValid: Bool { !email.isEmpty && !password.isEmpty }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.happySand)
                    .frame(width: 36, height: 4)
                    .padding(.top, HappySpacing.md)
                    .padding(.bottom, HappySpacing.xxl)

                VStack(alignment: .leading, spacing: 0) {
                    // Dev badge
                    Text("DEV MODE")
                        .font(HappyFont.bodyMedium(size: 10))
                        .tracking(2)
                        .foregroundColor(.happyAccentDark)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.happyAccent.opacity(0.12))
                        .overlay(Capsule().stroke(Color.happyAccent.opacity(0.3), lineWidth: 1))
                        .clipShape(Capsule())
                        .padding(.bottom, HappySpacing.md)

                    Text("Email Sign In")
                        .font(HappyFont.displayHeadline(size: 36))
                        .foregroundColor(.happyGreen)
                        .padding(.bottom, HappySpacing.xs)

                    Text("Password auth — debug builds only.")
                        .font(HappyFont.bodyLight(size: 14))
                        .foregroundColor(.happyMuted)
                        .padding(.bottom, HappySpacing.xxl)

                    VStack(spacing: HappySpacing.md) {
                        HappyTextField(
                            label: "Email",
                            placeholder: "you@example.com",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        HappyTextField(
                            label: "Password",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true
                        )
                    }
                    .padding(.bottom, HappySpacing.xl)

                    if let error = authManager.error {
                        Text(error)
                            .font(HappyFont.metaSmall)
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.bottom, HappySpacing.md)
                    }

                    HappyPrimaryButton(title: "Sign In →", fullWidth: true) {
                        Task { await authManager.signIn(email: email, password: password) }
                    }
                    .opacity(isValid ? 1 : 0.4)
                    .disabled(!isValid)

                    HappyOutlineButton(title: "Cancel", fullWidth: true) {
                        dismiss()
                    }
                    .padding(.top, HappySpacing.xs)

                    Button("Skip Auth (Dev)") {
                        authManager.devBypass = true
                        dismiss()
                    }
                    .font(HappyFont.metaSmall)
                    .foregroundColor(.happyMuted)
                    .padding(.top, HappySpacing.md)
                }
                .padding(.horizontal, HappySpacing.xl)

                Spacer()
            }
        }
        .overlay {
            if authManager.isLoading {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView().tint(.happyGreen).scaleEffect(1.4)
            }
        }
        .onChange(of: authManager.isSignedIn) { _, signedIn in
            if signedIn { dismiss() }
        }
    }
}

#Preview {
    DevLoginView()
        .environmentObject(AuthManager())
}
