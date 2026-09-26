import Foundation

/// An sRGB color token stored as plain numbers so contrast can be checked in tests.
public struct RGB: Sendable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double

    /// Hex like `0xFF3B30`.
    public init(_ hex: UInt32) {
        red = Double((hex >> 16) & 0xFF) / 255
        green = Double((hex >> 8) & 0xFF) / 255
        blue = Double(hex & 0xFF) / 255
    }

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// WCAG relative luminance.
    public var luminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// WCAG contrast ratio, from 1 to 21.
    public func contrast(with other: RGB) -> Double {
        let lighter = max(luminance, other.luminance)
        let darker = min(luminance, other.luminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

/// Fill and label for one session tag. The label always sits on the fill, so it's what needs contrast.
public struct TagColors: Sendable, Hashable {
    public let fill: RGB
    public let label: RGB
}

/// Every color token for one appearance.
public struct Palette: Sendable, Hashable {
    public let background: RGB
    public let card: RGB
    public let accent: RGB
    public let text: RGB
    public let secondaryText: RGB
    /// Label on a solid accent fill, like the primary button.
    public let onAccent: RGB
    /// Hairlines between rows and around cards.
    public let separator: RGB
    public let practice: TagColors
    public let qualifying: TagColors
    public let sprint: TagColors
    public let race: TagColors

    /// "The grid at night", the design tokens as given.
    public static let dark = Palette(
        background: RGB(0x0E0F12),
        card: RGB(0x1A1C21),
        accent: RGB(0xFF3B30),
        text: RGB(0xF2F2F2),
        secondaryText: RGB(0x8A8F98),
        // white on #FF3B30 is only 3.5:1, so dark mode buttons get dark labels
        onAccent: RGB(0x0E0F12),
        separator: RGB(0x2A2D34),
        practice: TagColors(fill: RGB(0x8A8F98), label: RGB(0x0E0F12)),
        qualifying: TagColors(fill: RGB(0xFFB020), label: RGB(0x0E0F12)),
        sprint: TagColors(fill: RGB(0x32D2F5), label: RGB(0x0E0F12)),
        race: TagColors(fill: RGB(0xFF3B30), label: RGB(0x0E0F12))
    )

    // same hues, darker where the dark-mode value can't reach 4.5:1 on white
    public static let light = Palette(
        background: RGB(0xF4F5F7),
        card: RGB(0xFFFFFF),
        accent: RGB(0xD70015),
        text: RGB(0x0E0F12),
        secondaryText: RGB(0x5A5F68),
        onAccent: RGB(0xFFFFFF),
        separator: RGB(0xE1E3E8),
        practice: TagColors(fill: RGB(0x5A5F68), label: RGB(0xFFFFFF)),
        qualifying: TagColors(fill: RGB(0xFFB020), label: RGB(0x0E0F12)),
        sprint: TagColors(fill: RGB(0x32D2F5), label: RGB(0x0E0F12)),
        race: TagColors(fill: RGB(0xD70015), label: RGB(0xFFFFFF))
    )

    public var tags: [TagColors] { [practice, qualifying, sprint, race] }
}
