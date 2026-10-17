import SwiftUI
import BigBackData
import DesignSystem
import Onboarding

/// Switches on the session: sign-in flow → profile setup (new accounts) → the app.
struct RootView: View {
    let environment: AppEnvironment

    var body: some View {
        Group {
            switch environment.session.phase {
            case .loading:
                ProgressView()
            case .signedOut:
                AuthFlowView(auth: environment.auth, legal: environment.legal)
            case .needsProfile(let email):
                ProfileSetupView(email: email, profiles: environment.profiles, legal: environment.legal) {
                    Task { await environment.session.refresh() }
                }
            case .ready:
                MainTabView(environment: environment)
            }
        }
        .animation(Motion.smooth, value: environment.session.phase)
    }
}
