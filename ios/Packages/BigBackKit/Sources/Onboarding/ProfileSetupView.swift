import SwiftUI
import Observation
import BigBackCore
import DesignSystem

/// "Make it yours": name, username (checked live) and the required terms checkbox.
/// App Review guideline 1.2: users must agree to terms with zero tolerance for objectionable content.
@MainActor
@Observable
public final class ProfileSetupModel {
    public var name: String
    public var handle: String
    public var agreed = false
    public private(set) var handleState: HandleState = .empty
    public private(set) var errorMessage: String?
    public private(set) var isSaving = false

    private let profiles: any ProfileService
    private let onFinished: @MainActor () -> Void

    public init(email: String, profiles: any ProfileService, onFinished: @escaping @MainActor () -> Void) {
        self.name = AuthValidation.suggestedName(fromEmail: email)
        self.handle = AuthValidation.suggestedHandle(fromEmail: email)
        self.profiles = profiles
        self.onFinished = onFinished
    }

    var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && handleState == .available && agreed && !isSaving
    }

    /// Debounced availability check; called from `.task(id: handle)`, so typing cancels the previous check.
    func checkHandle() async {
        let candidate = handle
        guard !candidate.isEmpty else { handleState = .empty; return }
        guard AuthValidation.isValidHandle(candidate) else { handleState = .invalid; return }
        handleState = .checking
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled, candidate == handle else { return }
        do {
            handleState = try await profiles.isHandleAvailable(candidate) ? .available : .taken
        } catch {
            if !Task.isCancelled { handleState = .unknown }
        }
    }

    func submit() async {
        guard canContinue else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await profiles.completeOnboarding(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                handle: handle,
                termsVersion: Terms.version
            )
            onFinished()
        } catch ProfileFailure.handleTaken {
            handleState = .taken
        } catch {
            errorMessage = AuthFailure.unknown.message
        }
    }
}

public struct ProfileSetupView: View {
    @State private var model: ProfileSetupModel
    private let legal: LegalLinks

    public init(email: String, profiles: any ProfileService, legal: LegalLinks, onFinished: @escaping @MainActor () -> Void) {
        _model = State(initialValue: ProfileSetupModel(email: email, profiles: profiles, onFinished: onFinished))
        self.legal = legal
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader("Make it yours", subtitle: "This is how friends find you. You can change it later.")
                LabeledField("Name") {
                    TextField("Your name", text: $model.name)
                        .textContentType(.name)
                        .submitLabel(.next)
                }
                .padding(.top, 24)
                LabeledField("Username", hasError: model.handleState == .taken) {
                    HStack(spacing: 2) {
                        Text("@").foregroundStyle(.secondary)
                        TextField("username", text: $model.handle)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                .padding(.top, 14)
                HandleStatus(state: model.handleState, handle: model.handle)
                    .padding(.top, 8)
                TermsCheckbox(agreed: $model.agreed, legal: legal)
                    .padding(.top, 20)
                if let error = model.errorMessage {
                    ErrorText(error).padding(.top, 12)
                }
                Button {
                    Task { await model.submit() }
                } label: {
                    if model.isSaving { ProgressView() } else { Text("Continue") }
                }
                .buttonStyle(.bbPrimary)
                .disabled(!model.canContinue)
                .padding(.top, 24)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .task(id: model.handle) { await model.checkHandle() }
        .animation(Motion.snap, value: model.handleState)
        .tint(Theme.accent)
    }
}

struct HandleStatus: View {
    let state: HandleState
    let handle: String

    var body: some View {
        switch state {
        case .available:
            Label("@\(handle) is available", systemImage: "checkmark.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.accent)
        case .taken:
            ErrorText("@\(handle) is taken. Try another.")
        case .checking, .empty, .invalid, .unknown:
            Text(state.message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

struct TermsCheckbox: View {
    @Binding var agreed: Bool
    let legal: LegalLinks

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                agreed.toggle()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: agreed ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(agreed ? Theme.accent : Color.secondary)
                        .contentTransition(.symbolEffect(.replace))
                    Text("I agree to the Terms of Use and Community Guidelines. No hate, harassment, nudity or targeting people. Zero tolerance.")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
            }
            .buttonStyle(.plain)
            .accessibilityValue(agreed ? "Checked" : "Not checked")
            .accessibilityAddTraits(.isToggle)
            .sensoryFeedback(.selection, trigger: agreed)
            HStack(spacing: 16) {
                Link("Terms of Use", destination: legal.terms)
                Link("Guidelines", destination: legal.guidelines)
                Link("Privacy", destination: legal.privacy)
            }
            .font(.footnote.weight(.semibold))
            .padding(.leading, 36)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
