import Foundation

public enum SignInMode: Sendable {
    case signUp, logIn
}

/// Sign-in by emailed 6-digit code (docs/design/04-sign-up-and-login.md).
/// Session changes are observed separately (BigBackData.SessionStore), so these calls don't return a session.
public protocol AuthService: Sendable {
    func sendCode(to email: String, mode: SignInMode) async throws
    func verify(email: String, code: String) async throws
    /// Test and App Review accounts only (`signup_allowlist`).
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    /// Calls the `delete-account` Edge Function, then signs out.
    func deleteAccount() async throws
}

public protocol ProfileService: Sendable {
    func isHandleAvailable(_ handle: String) async throws -> Bool
    func completeOnboarding(name: String, handle: String, termsVersion: String) async throws
}

public enum AuthFailure: Error, Equatable, Sendable {
    case notUW, wrongCode, wrongPassword, tooManyTries, offline, unknown

    public var message: String {
        switch self {
        case .notUW: EmailProblem.notUW.message
        case .wrongCode: "That code didn’t work. Check your latest email, or send a new code."
        case .wrongPassword: "That email and password don’t match."
        case .tooManyTries: "Too many tries. Wait a minute and try again."
        case .offline: "You’re offline. Connect and try again."
        case .unknown: "Something went wrong. Try again."
        }
    }
}

public enum ProfileFailure: Error, Equatable, Sendable {
    case handleTaken
}

/// Public pages on the BigBack domain (web/).
public struct LegalLinks: Sendable {
    public let terms: URL
    public let privacy: URL
    public let guidelines: URL
    public let support: URL

    public init(base: URL) {
        terms = base.appending(path: "terms.html")
        privacy = base.appending(path: "privacy.html")
        guidelines = base.appending(path: "guidelines.html")
        support = base.appending(path: "support.html")
    }
}

/// Version of the Terms the app asks people to accept. Keep in sync with web/terms.html.
public enum Terms {
    public static let version = "2026-10"
}
