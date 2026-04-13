import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

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

    // MARK: - Sign in with Apple (programmatic)

    private var currentNonce: String = ""
    private var appleSignInDelegate: AppleSignInDelegate?

    func startAppleSignIn() {
        currentNonce = randomNonceString()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(currentNonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let idToken):
                Task { await self.signInWithApple(idToken: idToken, nonce: self.currentNonce) }
            case .failure(let err):
                Task { @MainActor in self.error = err.localizedDescription }
            }
        }
        self.appleSignInDelegate = delegate
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
    }

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
                if random < charset.count { result.append(charset[Int(random)]); remainingLength -= 1 }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true
        error = nil
        do {
            session = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
        } catch let err {
            error = err.localizedDescription
            print("❌ signInWithApple error: \(err)")
        }
        isLoading = false
    }

    // MARK: - Email + Password

    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            session = try await supabase.auth.signIn(email: email, password: password)
        } catch let err {
            error = err.localizedDescription
        }
        isLoading = false
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            let response = try await supabase.auth.signUp(email: email, password: password)
            session = response.session
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

// MARK: - Apple Sign In Delegate

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<String, Error>) -> Void

    init(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = cred.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            completion(.failure(NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"])))
            return
        }
        completion(.success(idToken))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
