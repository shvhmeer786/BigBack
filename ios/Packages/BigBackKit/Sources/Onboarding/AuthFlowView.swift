import SwiftUI
import BigBackCore
import DesignSystem

/// Signed-out root: Welcome, then email and code in a navigation stack (so swipe-back works).
public struct AuthFlowView: View {
    @State private var model: AuthFlowModel
    private let legal: LegalLinks

    public init(auth: any AuthService, legal: LegalLinks) {
        _model = State(initialValue: AuthFlowModel(auth: auth))
        self.legal = legal
    }

    public var body: some View {
        NavigationStack(path: $model.path) {
            WelcomeView(
                onSignUp: { model.begin(.signUp) },
                onLogIn: { model.begin(.logIn) }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AuthStep.self) { step in
                switch step {
                case .email: EmailStepView(model: model, legal: legal)
                case .code: CodeStepView(model: model)
                }
            }
        }
        .tint(Theme.accent)
    }
}

// MARK: Welcome

struct WelcomeView: View {
    let onSignUp: () -> Void
    let onLogIn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Wordmark(size: 46)
            Text("Where Waterloo eats.")
                .font(.title2.weight(.semibold))
                .padding(.top, 12)
            Text("Snap the meal, rank it in three swipes, and see where your friends actually eat.")
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            Spacer(minLength: 16)
            MealCardStack()
                .frame(maxWidth: .infinity)
            Spacer(minLength: 16)
            VStack(spacing: 6) {
                Button("Sign up with your UW email", action: onSignUp)
                    .buttonStyle(.bbPrimary)
                Button("I have an account · Log in", action: onLogIn)
                    .buttonStyle(.bbText)
                Text("For University of Waterloo students. More campuses soon.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 12)
    }
}

/// Decorative stack of meal cards; pops in with a spring (a fade under Reduce Motion).
struct MealCardStack: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        ZStack {
            card(Color(light: 0x6B6259, dark: 0x6B6259)).rotationEffect(.degrees(-8)).offset(x: -70, y: 10)
            card(Color(light: 0x1F5C3E, dark: 0x1F5C3E)).rotationEffect(.degrees(7)).offset(x: 70, y: -8)
            card(Theme.accentTint)
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(light: 0x2E2A27, dark: 0x2E2A27))
                        .frame(width: 44, height: 58)
                        .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white, lineWidth: 2) }
                        .padding(10)
                }
                .overlay(alignment: .bottom) {
                    HStack(spacing: 8) {
                        Text("9.2")
                            .font(.rounded(.subheadline, weight: .heavy))
                            .foregroundStyle(Theme.onAccent)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Gol’s Lanzhou").font(.caption.weight(.semibold))
                            Text("Loved it").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(10)
                }
                .shadow(color: .black.opacity(0.18), radius: 20, y: 12)
        }
        .frame(height: 260)
        .scaleEffect(shown || reduceMotion ? 1 : 0.85)
        .opacity(shown ? 1 : 0)
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : Motion.bouncy) { shown = true }
        }
        .accessibilityHidden(true)
    }

    private func card(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(color.gradient)
            .frame(width: 160, height: 210)
    }
}

// MARK: Email

struct EmailStepView: View {
    @Bindable var model: AuthFlowModel
    let legal: LegalLinks
    @FocusState private var focused: Bool

    private var isLogIn: Bool { model.mode == .logIn }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(
                isLogIn ? "Welcome back" : "What’s your UW email?",
                subtitle: isLogIn
                    ? (model.usePassword
                        ? "Test and App Review accounts can sign in with a password."
                        : "We’ll email you a code to log in. No password to remember.")
                    : "We’ll email you a 6-digit code to confirm it’s really you. No password needed."
            )
            LabeledField("UW email", hasError: model.errorMessage != nil) {
                TextField("you@uwaterloo.ca", text: $model.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.continue)
                    .focused($focused)
                    .onSubmit { Task { await model.submitEmail() } }
            }
            .padding(.top, 24)
            if isLogIn && model.usePassword {
                LabeledField("Password") {
                    SecureField("Password", text: $model.password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .onSubmit { Task { await model.submitEmail() } }
                }
                .padding(.top, 14)
            }
            if let error = model.errorMessage {
                ErrorText(error).padding(.top, 10)
            }
            Spacer()
            Button {
                Task { await model.submitEmail() }
            } label: {
                if model.isBusy { ProgressView() } else { Text(isLogIn && model.usePassword ? "Log in" : "Send code") }
            }
            .buttonStyle(.bbPrimary)
            .disabled(model.isBusy)
            if isLogIn {
                Button(model.usePassword ? "Email me a code instead" : "Use a password instead") {
                    model.usePassword.toggle()
                    model.clearError()
                }
                .buttonStyle(.bbText)
            }
            HStack(spacing: 4) {
                Text("We use your email only to sign you in and confirm you’re at UW.")
                Link("Privacy", destination: legal.privacy).fontWeight(.semibold)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
        .onChange(of: model.email) { model.clearError() }
        .animation(Motion.snap, value: model.errorMessage)
    }
}

// MARK: Code

struct CodeStepView: View {
    @Bindable var model: AuthFlowModel
    @FocusState private var focused: Bool
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader("Check your email")
            Text("Enter the 6-digit code we sent to \(Text(model.email).bold()).")
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            ZStack {
                HStack(spacing: 8) {
                    ForEach(0..<AuthValidation.codeLength, id: \.self) { index in
                        CodeBox(
                            digit: digit(at: index),
                            isActive: focused && index == model.code.count && !model.isBusy,
                            hasError: model.errorMessage != nil
                        )
                    }
                }
                TextField("", text: $model.code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focused)
                    .foregroundStyle(.clear)
                    .tint(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(0.02)
                    .accessibilityLabel("6-digit code")
            }
            .frame(height: 60)
            .padding(.top, 26)
            .contentShape(Rectangle())
            .onTapGesture { focused = true }
            .onChange(of: model.code) { model.codeChanged() }

            Group {
                if model.isBusy {
                    Text("Checking…").foregroundStyle(.secondary)
                } else if let error = model.errorMessage {
                    ErrorText(error)
                } else if model.resendSeconds > 0 {
                    Text("You can ask for a new code in 0:\(model.resendSeconds, format: .number.precision(.integerLength(2)))")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                } else {
                    Button("Send a new code") { Task { await model.resend() } }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .font(.subheadline)
            .padding(.top, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
            Button("Open Mail") {
                if let url = URL(string: "message://") { openURL(url) }
            }
            .buttonStyle(.bbSecondary)
            Button("Wrong email? Change it") {
                model.path.removeLast()
            }
            .buttonStyle(.bbText)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
        .sensoryFeedback(.error, trigger: model.errorMessage) { _, new in new != nil }
    }

    private func digit(at index: Int) -> String {
        let digits = Array(model.code)
        return index < digits.count ? String(digits[index]) : ""
    }
}

struct CodeBox: View {
    let digit: String
    let isActive: Bool
    let hasError: Bool

    var body: some View {
        Text(digit)
            .font(.rounded(.title))
            .monospacedDigit()
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(hasError ? Theme.error : (isActive ? Theme.accent : Color.clear), lineWidth: 1.5)
            }
            .animation(Motion.snap, value: isActive)
            .accessibilityHidden(true)
    }
}
