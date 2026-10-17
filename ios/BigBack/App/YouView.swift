import SwiftUI
import BigBackCore
import DesignSystem

/// You → Account: Log out and Delete account (App Review guideline 5.1.1(v): deletion within the app).
struct YouView: View {
    let environment: AppEnvironment
    @State private var confirmingDelete = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Account") {
                Button("Log out") {
                    Task { try? await environment.auth.signOut() }
                }
                Button("Delete account", role: .destructive) {
                    confirmingDelete = true
                }
                .disabled(isDeleting)
            }
            Section("About") {
                Link("Community Guidelines", destination: environment.legal.guidelines)
                Link("Privacy Policy", destination: environment.legal.privacy)
                Link("Terms of Use", destination: environment.legal.terms)
                Link("Help & support", destination: environment.legal.support)
            }
        }
        .navigationTitle("You")
        .overlay {
            if isDeleting { ProgressView("Deleting…").padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14)) }
        }
        .confirmationDialog("Delete your account?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("This permanently deletes your profile, posts, photos and rankings. It can’t be undone.")
        }
        .alert("Couldn’t delete your account", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await environment.auth.deleteAccount()
            environment.session.markSignedOut()
        } catch {
            errorMessage = "Check your connection and try again. If it keeps happening, contact support."
        }
    }
}
