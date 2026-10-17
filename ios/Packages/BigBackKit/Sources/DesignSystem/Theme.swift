import SwiftUI
import UIKit

/// Colour tokens from docs/design/03-design-system.md. One hue: racing green plus iOS system neutrals.
public enum Theme {
    public static let accent = Color(light: 0x004225, dark: 0x3FA46E)
    public static let accentPressed = Color(light: 0x00301B, dark: 0x2F8A5A)
    public static let accentSoft = Color(light: 0xE4F0E8, dark: 0x12291E)
    public static let onAccent = Color(light: 0xFFFFFF, dark: 0x04140C)
    public static let accentTint = Color(light: 0x3E7C59, dark: 0x9CCFB0)
    /// Destructive actions and error messages only.
    public static let error = Color(light: 0xD70015, dark: 0xFF6961)
}

/// Motion tokens. Celebration springs are for celebrations only.
public enum Motion {
    public static let snap = Animation.snappy(duration: 0.25)
    public static let smooth = Animation.smooth(duration: 0.35)
    public static let bouncy = Animation.bouncy(duration: 0.5, extraBounce: 0.1)
    public static let reveal = Animation.spring(response: 0.55, dampingFraction: 0.82)
}

public extension Color {
    /// A colour that follows Dark Mode, from two 0xRRGGBB values.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

public extension Font {
    /// Rounded titles: large titles, scores and the wordmark.
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}
