import Foundation
import BigBackCore
import BigBackData
import Supabase

/// Composition root: builds the live services once and hands them to the features.
@MainActor
final class AppEnvironment {
    let session: SessionStore
    let auth: any AuthService
    let profiles: any ProfileService
    let legal: LegalLinks

    init(bundle: Bundle = .main) {
        guard
            let urlString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: urlString),
            let key = bundle.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String,
            !key.isEmpty
        else {
            fatalError("SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY missing: check ios/Config/Supabase.xcconfig")
        }
        let client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        session = SessionStore(client: client)
        auth = SupabaseAuthService(client: client)
        profiles = SupabaseProfileService(client: client)

        let legalBase = (bundle.object(forInfoDictionaryKey: "LEGAL_BASE_URL") as? String).flatMap(URL.init(string:))
        legal = LegalLinks(base: legalBase ?? URL(string: "https://bigback.example")!)
    }
}
