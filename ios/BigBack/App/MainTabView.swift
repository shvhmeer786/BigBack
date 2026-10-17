import SwiftUI
import DesignSystem

/// Four tabs (HIG: tabs navigate, the camera is an action). Feature screens replace the placeholders as they land.
struct MainTabView: View {
    let environment: AppEnvironment

    var body: some View {
        TabView {
            Tab("Feed", systemImage: "rectangle.stack") {
                NavigationStack {
                    ComingNext(symbol: "rectangle.stack", title: "Your feed", message: "Meals from people you follow show up here.")
                        .navigationTitle("Feed")
                }
            }
            Tab("Tonight", systemImage: "fork.knife") {
                NavigationStack {
                    ComingNext(symbol: "fork.knife", title: "Tonight", message: "Picks near you, from Apple Maps plus your friends’ scores.")
                        .navigationTitle("Tonight")
                }
            }
            Tab("Activity", systemImage: "bell") {
                NavigationStack {
                    ComingNext(symbol: "bell", title: "Activity", message: "Follows, tags, invites and reactions.")
                        .navigationTitle("Activity")
                }
            }
            Tab("You", systemImage: "person.crop.circle") {
                NavigationStack {
                    YouView(environment: environment)
                }
            }
        }
    }
}

private struct ComingNext: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView(title, systemImage: symbol, description: Text(message))
    }
}
