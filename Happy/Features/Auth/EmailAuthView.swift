import SwiftUI

struct EmailAuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    enum Mode { case signIn, createAccount }
    @State private var mode: Mode = .signIn

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var passwordsMatch: Bool { password == confirmPassword }
    private var isValid: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        let passwordOK = password.count >= 8
        if mode == .createAccount { return emailOK && passwordOK && passwordsMatch }
        return emailOK && passwordOK
    }

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
                    // Mode toggle
                    HStack(spacing: 2) {
                        modeTab("Sign In", selected: mode == .signIn) { mode = .signIn }
                        modeTab("Create Account", selected: mode == .createAccount) { mode = .createAccount }
                    }
                    .padding(3)
                    .background(Color.happySandLight.opacity(0.6))
                    .cornerRadius(HappyRadius.input + 3)
                    .padding(.bottom, HappySpacing.xxl)

                    // Headline
                    Text(mode == .signIn ? "Welcome\nback." : "Join\nHappy.")
                        .font(HappyFont.displayHeadline(size: 40))
                        .foregroundColor(.happyGreen)
                        .lineSpacing(4)
                        .padding(.bottom, HappySpacing.xs)

                    Text(mode == .signIn ? "Sign in to your account." : "Create your account to get started.")
                        .font(HappyFont.bodyLight(size: 14))
                        .foregroundColor(.happyMuted)
                        .padding(.bottom, HappySpacing.xxl)

                    // Fields
                    VStack(spacing: HappySpacing.md) {
                        HappyTextField(
                            label: "Email Address",
                            placeholder: "you@example.com",
                            text: $email,
                            keyboardType: .emailAddress,
                            isRequired: true
                        )
                        HappyTextField(
                            label: "Password",
                            placeholder: mode == .createAccount ? "At least 8 characters" : "Password",
                            text: $password,
                            isRequired: true,
                            isSecure: true
                        )
                        if mode == .createAccount {
                            HappyTextField(
                                label: "Confirm Password",
                                placeholder: "Re-enter your password",
                                text: $confirmPassword,
                                isRequired: true,
                                isSecure: true
                            )
                            if !confirmPassword.isEmpty && !passwordsMatch {
                                Text("Passwords don't match.")
                                    .font(HappyFont.metaSmall)
                                    .foregroundColor(.red.opacity(0.75))
                            }
                        }
                    }
                    .padding(.bottom, HappySpacing.xl)

                    if let error = authManager.error {
                        Text(error)
                            .font(HappyFont.metaSmall)
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.bottom, HappySpacing.md)
                    }

                    HappyPrimaryButton(
                        title: mode == .signIn ? "Sign In →" : "Create Account →",
                        fullWidth: true
                    ) {
                        Task {
                            if mode == .signIn {
                                await authManager.signIn(email: email, password: password)
                            } else {
                                await authManager.signUp(email: email, password: password)
                            }
                        }
                    }
                    .opacity(isValid ? 1 : 0.4)
                    .disabled(!isValid)

                    HappyOutlineButton(title: "Cancel", fullWidth: true) {
                        dismiss()
                    }
                    .padding(.top, HappySpacing.xs)
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
        .onChange(of: mode) { _, _ in
            authManager.error = nil
            confirmPassword = ""
        }
    }

    private func modeTab(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(HappyFont.bodyMedium(size: 13))
                .foregroundColor(selected ? .happyCream : .happyMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(selected ? Color.happyGreen : Color.clear)
                .cornerRadius(HappyRadius.input)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EmailAuthView()
        .environmentObject(AuthManager())
}
