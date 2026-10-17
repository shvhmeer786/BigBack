import Foundation
import BigBackCore
import Supabase

/// Live AuthService on Supabase Auth (email OTP). See docs/design/04-sign-up-and-login.md.
public struct SupabaseAuthService: AuthService {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func sendCode(to email: String, mode: SignInMode) async throws {
        do {
            // Log-in never creates an account, so a typo on that screen can't sign anyone up.
            try await client.auth.signInWithOTP(email: email, shouldCreateUser: mode == .signUp)
        } catch {
            throw AuthFailure.classify(error, fallback: .unknown)
        }
    }

    public func verify(email: String, code: String) async throws {
        do {
            _ = try await client.auth.verifyOTP(email: email, token: code, type: .email)
        } catch {
            throw AuthFailure.classify(error, fallback: .wrongCode)
        }
    }

    public func signIn(email: String, password: String) async throws {
        do {
            _ = try await client.auth.signIn(email: email, password: password)
        } catch {
            throw AuthFailure.classify(error, fallback: .wrongPassword)
        }
    }

    public func signOut() async throws {
        try await client.auth.signOut()
    }

    public func deleteAccount() async throws {
        try await client.functions.invoke(
            "delete-account",
            options: FunctionInvokeOptions(body: ["confirm": "DELETE"])
        )
        // The account is gone on the server; clear the local session too.
        try? await client.auth.signOut()
    }
}

/// Live ProfileService on the onboarding RPCs (migration auth_onboarding).
public struct SupabaseProfileService: ProfileService {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func isHandleAvailable(_ handle: String) async throws -> Bool {
        try await client.rpc("is_handle_available", params: ["p_handle": handle]).execute().value
    }

    public func completeOnboarding(name: String, handle: String, termsVersion: String) async throws {
        struct Params: Encodable, Sendable {
            let p_display_name: String
            let p_handle: String
            let p_terms_version: String
        }
        do {
            _ = try await client
                .rpc("complete_onboarding", params: Params(p_display_name: name, p_handle: handle, p_terms_version: termsVersion))
                .execute()
        } catch {
            let text = String(describing: error).lowercased()
            if text.contains("handle unavailable") || text.contains("23505") { throw ProfileFailure.handleTaken }
            throw error
        }
    }
}

extension AuthFailure {
    /// Maps Supabase Auth errors onto the messages in the sign-up spec.
    static func classify(_ error: any Error, fallback: AuthFailure) -> AuthFailure {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost, .dataNotAllowed:
                return .offline
            default:
                break
            }
        }
        let text = String(describing: error).lowercased()
        // Our Before User Created hook rejects non-UW emails with this message.
        if text.contains("campus-only") || text.contains("school email") { return .notUW }
        if text.contains("rate limit") || text.contains("rate_limit") || text.contains("429") { return .tooManyTries }
        return fallback
    }
}
