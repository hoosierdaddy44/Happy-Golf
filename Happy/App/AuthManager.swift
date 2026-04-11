import SwiftUI
import Supabase
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    @Published var session: Session?
    @Published var isReady = false   // true once initial session check completes
    @Published var isLoading = false
    @Published var error: String?

    @Published var devBypass: Bool = false
    var isSignedIn: Bool { devBypass || session != nil }

    init() {
        Task { await restoreSession() }
    }

    // MARK: - Session

    private func restoreSession() async {
        // Show UI immediately — don't block on network
        isReady = true

        // Keep listening for future auth changes (fires .signedIn on restore too)
        for await (event, newSession) in supabase.auth.authStateChanges {
            switch event {
            case .initialSession, .signedIn, .tokenRefreshed:
                session = newSession
            case .signedOut:
                session = nil
            default:
                break
            }
        }
    }

    // MARK: - Sign in with Apple

    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true
        error = nil
        do {
            session = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
        } catch let err {
            error = err.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Email Magic Link

    func sendMagicLink(email: String) async {
        isLoading = true
        error = nil
        do {
            try await supabase.auth.signInWithOTP(email: email)
        } catch let err {
            error = err.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Email + Password (dev only)

    func signInWithPassword(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            session = try await supabase.auth.signIn(email: email, password: password)
        } catch let err {
            error = err.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        do {
            try await supabase.auth.signOut()
            session = nil
        } catch let err {
            error = err.localizedDescription
        }
        isLoading = false
    }
}
