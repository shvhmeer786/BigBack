import Foundation
import Observation
import BigBackCore

public enum AuthStep: Hashable, Sendable {
    case email, code
}

/// Welcome → email → code. Sign-up and log-in are the same flow; a successful code (or password) signs the
/// user in, and the app's SessionStore moves on from there.
@MainActor
@Observable
public final class AuthFlowModel {
    public var path: [AuthStep] = []
    public private(set) var mode: SignInMode = .signUp
    public var email = ""
    public var password = ""
    public var usePassword = false
    public var code = ""
    public private(set) var errorMessage: String?
    public private(set) var isBusy = false
    public private(set) var resendSeconds = 0

    private let auth: any AuthService
    @ObservationIgnored private var resendTask: Task<Void, Never>?

    public init(auth: any AuthService) {
        self.auth = auth
    }

    func begin(_ mode: SignInMode) {
        self.mode = mode
        usePassword = false
        password = ""
        errorMessage = nil
        path = [.email]
    }

    func clearError() {
        errorMessage = nil
    }

    func submitEmail() async {
        guard !isBusy else { return }
        if let problem = AuthValidation.emailProblem(email) {
            errorMessage = problem.message
            return
        }
        let normalized = AuthValidation.normalizedEmail(email)
        email = normalized
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        do {
            if mode == .logIn && usePassword {
                guard !password.isEmpty else {
                    errorMessage = "Enter your password."
                    return
                }
                try await auth.signIn(email: normalized, password: password)
                return
            }
            try await auth.sendCode(to: normalized, mode: mode)
            code = ""
            startResendTimer()
            path.append(.code)
        } catch {
            errorMessage = ((error as? AuthFailure) ?? .unknown).message
        }
    }

    /// Called whenever the code field changes; verifies automatically on the 6th digit.
    func codeChanged() {
        let cleaned = AuthValidation.cleanCode(code)
        if cleaned != code { code = cleaned }
        if !cleaned.isEmpty { errorMessage = nil }
        if cleaned.count == AuthValidation.codeLength {
            Task { await verify(cleaned) }
        }
    }

    func resend() async {
        guard resendSeconds == 0, !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await auth.sendCode(to: email, mode: mode)
            code = ""
            errorMessage = nil
            startResendTimer()
        } catch {
            errorMessage = ((error as? AuthFailure) ?? .unknown).message
        }
    }

    private func verify(_ value: String) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await auth.verify(email: email, code: value)
            resendTask?.cancel()
        } catch {
            code = ""
            errorMessage = ((error as? AuthFailure) ?? .wrongCode).message
        }
    }

    private func startResendTimer() {
        resendTask?.cancel()
        resendSeconds = 30
        resendTask = Task {
            for remaining in stride(from: 29, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self.resendSeconds = remaining
            }
        }
    }
}
