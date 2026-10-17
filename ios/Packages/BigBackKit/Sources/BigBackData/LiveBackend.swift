import Foundation
import BigBackCore
import Supabase

/// The live services, built on one Supabase client. The app only sees the protocols, never Supabase itself.
@MainActor
public struct LiveBackend {
    public let session: SessionStore
    public let auth: any AuthService
    public let profiles: any ProfileService

    public init(url: URL, publishableKey: String) {
        let client = SupabaseClient(supabaseURL: url, supabaseKey: publishableKey)
        session = SessionStore(client: client)
        auth = SupabaseAuthService(client: client)
        profiles = SupabaseProfileService(client: client)
    }
}
