import SwiftUI
import DesignSystem

@main
struct BigBackApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView(environment: environment)
                .tint(Theme.accent)
                .task { environment.session.start() }
        }
    }
}
