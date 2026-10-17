import Foundation
import Observation
import Supabase

/// The signed-in state the app's root view switches on.
@MainActor
@Observable
public final class SessionStore {
    public enum Phase: Equatable, Sendable {
        case loading
        case signedOut
        /// Signed in, but hasn't picked a name and username or accepted the terms yet.
        case needsProfile(email: String)
        case ready
    }

    public private(set) var phase: Phase = .loading

    private let client: SupabaseClient
    @ObservationIgnored private var listener: Task<Void, Never>?

    public init(client: SupabaseClient) {
        self.client = client
    }

    /// Follows Supabase Auth for the life of the app (initial session, sign-in, sign-out, refresh).
    public func start() {
        guard listener == nil else { return }
        listener = Task { [weak self] in
            guard let changes = self?.client.auth.authStateChanges else { return }
            for await change in changes {
                await self?.apply(change.session)
            }
        }
    }

    /// Re-checks the profile, e.g. after onboarding finishes.
    public func refresh() async {
        await apply(try? await client.auth.session)
    }

    /// After Delete account: don't wait for the auth event.
    public func markSignedOut() {
        phase = .signedOut
    }

    private func apply(_ session: Session?) async {
        guard let session, !session.isExpired else {
            phase = .signedOut
            return
        }
        struct Row: Decodable { let onboarded_at: String? }
        do {
            let rows: [Row] = try await client
                .from("profiles")
                .select("onboarded_at")
                .eq("id", value: session.user.id.uuidString)
                .limit(1)
                .execute()
                .value
            phase = rows.first?.onboarded_at == nil ? .needsProfile(email: session.user.email ?? "") : .ready
        } catch {
            // Offline at launch: let returning users in; the feed shows its own offline state.
            phase = .ready
        }
    }
}
