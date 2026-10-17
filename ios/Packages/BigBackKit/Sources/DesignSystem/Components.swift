import SwiftUI

// MARK: Buttons

/// Capsule, 54 pt, accent fill. One per screen.
public struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(isEnabled ? Theme.onAccent : Color.secondary)
            .background(isEnabled ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(HierarchicalShapeStyle.quaternary), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.snap, value: configuration.isPressed)
    }
}

/// Tinted capsule for the secondary action (Open Mail, Share invite).
public struct SecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(Theme.accent)
            .background(Theme.accentSoft, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.snap, value: configuration.isPressed)
    }
}

/// Plain accent text with a 44 pt tap target.
public struct TextButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var bbPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

public extension ButtonStyle where Self == SecondaryButtonStyle {
    static var bbSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

public extension ButtonStyle where Self == TextButtonStyle {
    static var bbText: TextButtonStyle { TextButtonStyle() }
}

// MARK: Text

/// "BigBack." in rounded heavy, with the full stop in the accent colour.
public struct Wordmark: View {
    let size: CGFloat

    public init(size: CGFloat = 34) {
        self.size = size
    }

    public var body: some View {
        Text("BigBack\(Text(".").foregroundStyle(Theme.accent))")
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .kerning(-size * 0.025)
            .accessibilityLabel("BigBack")
    }
}

/// A screen title plus the line under it.
public struct ScreenHeader: View {
    let title: String
    let subtitle: String?

    public init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.rounded(.largeTitle))
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Error text: accessible red with an icon, so colour is never the only signal.
public struct ErrorText: View {
    let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var body: some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(.subheadline)
            .foregroundStyle(Theme.error)
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity)
    }
}

// MARK: Fields

/// Label above a rounded, filled field. The border turns red when there's an error.
public struct LabeledField<Content: View>: View {
    let title: String
    let hasError: Bool
    let content: Content

    public init(_ title: String, hasError: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.hasError = hasError
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            content
                .font(.body)
                .padding(.horizontal, 16)
                .frame(minHeight: 52)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(hasError ? Theme.error : Color.clear, lineWidth: 1.5)
                }
        }
    }
}
