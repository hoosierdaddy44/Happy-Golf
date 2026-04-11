import SwiftUI

struct EmailAuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var sent = false

    private var isValid: Bool {
        email.contains("@") && email.contains(".")
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

                if sent {
                    sentState
                } else {
                    entryState
                }

                Spacer()
            }
            .padding(.horizontal, HappySpacing.xl)
        }
        .overlay {
            if authManager.isLoading {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView().tint(.happyGreen).scaleEffect(1.4)
            }
        }
    }

    private var entryState: some View {
        VStack(alignment: .leading, spacing: 0) {
            HappySectionLabel(text: "Email Sign In")
                .padding(.bottom, HappySpacing.md)

            Text("Enter your\nemail.")
                .font(HappyFont.displayHeadline(size: 40))
                .foregroundColor(.happyGreen)
                .lineSpacing(4)
                .padding(.bottom, HappySpacing.xs)

            Text("We'll send a magic link — no password needed.")
                .font(HappyFont.bodyLight(size: 14))
                .foregroundColor(.happyMuted)
                .padding(.bottom, HappySpacing.xxl)

            HappyTextField(
                label: "Email Address",
                placeholder: "you@example.com",
                text: $email,
                keyboardType: .emailAddress,
                isRequired: true
            )
            .padding(.bottom, HappySpacing.xl)

            if let error = authManager.error {
                Text(error)
                    .font(HappyFont.metaSmall)
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.bottom, HappySpacing.md)
            }

            HappyPrimaryButton(title: "Send Magic Link →", fullWidth: true) {
                Task { await authManager.sendMagicLink(email: email) }
                withAnimation { sent = true }
            }
            .opacity(isValid ? 1 : 0.4)
            .disabled(!isValid)

            HappyOutlineButton(title: "Cancel", fullWidth: true) {
                dismiss()
            }
            .padding(.top, HappySpacing.xs)
        }
    }

    private var sentState: some View {
        VStack(spacing: HappySpacing.xl) {
            Spacer().frame(height: HappySpacing.section)

            Text("⛳")
                .font(.system(size: 56))

            VStack(spacing: HappySpacing.sm) {
                Text("Check your email.")
                    .font(HappyFont.displayHeadline(size: 32))
                    .foregroundColor(.happyGreen)
                    .multilineTextAlignment(.center)

                Text("We sent a magic link to\n\(email)")
                    .font(HappyFont.bodyLight(size: 15))
                    .foregroundColor(.happyMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            HappyOutlineButton(title: "Back to Sign In") {
                withAnimation { sent = false }
            }
        }
    }
}

#Preview {
    EmailAuthView()
        .environmentObject(AuthManager())
}
