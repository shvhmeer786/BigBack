import Foundation

/// Why an email can't be used to sign up. The server's Before User Created hook enforces the same rule.
public enum EmailProblem: Equatable, Sendable {
    case empty, malformed, notUW

    public var message: String {
        switch self {
        case .empty: "Enter your UW email to continue."
        case .malformed: "That doesn’t look like an email address."
        case .notUW: "BigBack is only for UW students right now. Use your @uwaterloo.ca email."
        }
    }
}

public enum HandleState: Equatable, Sendable {
    case empty, invalid, checking, taken, available, unknown

    public var message: String {
        switch self {
        case .empty, .invalid: "3–24 letters, numbers, _ or ."
        case .checking: "Checking…"
        case .taken: "That username is taken. Try another."
        case .available: "Available"
        case .unknown: "Can’t check usernames right now. Check your connection."
        }
    }
}

public enum AuthValidation {
    public static let schoolDomain = "uwaterloo.ca"
    public static let codeLength = 6

    private static let handleCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_."
    )

    public static func normalizedEmail(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// `nil` means the email can be used. Subdomains of uwaterloo.ca are accepted, look-alikes are not.
    public static func emailProblem(_ raw: String) -> EmailProblem? {
        let email = normalizedEmail(raw)
        guard !email.isEmpty else { return .empty }
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2,
              !parts[0].isEmpty,
              parts[1].contains("."),
              !parts[1].hasPrefix("."), !parts[1].hasSuffix("."),
              !email.contains(where: \.isWhitespace)
        else { return .malformed }
        let domain = parts[1]
        return domain == schoolDomain || domain.hasSuffix("." + schoolDomain) ? nil : .notUW
    }

    /// Same rule as `profiles.handle` in the database: 3–24 of `[A-Za-z0-9_.]`.
    public static func isValidHandle(_ handle: String) -> Bool {
        (3...24).contains(handle.count) && handle.unicodeScalars.allSatisfy { handleCharacters.contains($0) }
    }

    /// "maya.chen@uwaterloo.ca" → "maya.chen"
    public static func suggestedHandle(fromEmail email: String) -> String {
        let local = normalizedEmail(email).split(separator: "@").first.map(String.init) ?? ""
        var handle = ""
        for scalar in local.unicodeScalars where handleCharacters.contains(scalar) {
            handle.unicodeScalars.append(scalar)
        }
        return String(handle.prefix(24))
    }

    /// "maya.chen@uwaterloo.ca" → "Maya Chen"
    public static func suggestedName(fromEmail email: String) -> String {
        let local = normalizedEmail(email).split(separator: "@").first ?? ""
        return local
            .split(whereSeparator: { ".-_".contains($0) })
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    /// Keeps ASCII digits only, at most 6, so pasted or autofilled codes like "482 913" work.
    public static func cleanCode(_ raw: String) -> String {
        String(raw.filter { $0.isASCII && $0.isNumber }.prefix(codeLength))
    }
}
