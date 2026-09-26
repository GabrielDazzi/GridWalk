import GridWalkKit
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Color tokens that follow the system appearance. Views use these, never raw colors.
public enum Theme {
    public static let background = adaptive(\.background)
    public static let card = adaptive(\.card)
    public static let accent = adaptive(\.accent)
    public static let text = adaptive(\.text)
    public static let secondaryText = adaptive(\.secondaryText)
    public static let onAccent = adaptive(\.onAccent)
    public static let separator = adaptive(\.separator)

    public static func tagFill(for category: AlertCategory) -> Color {
        adaptive { $0.tagColors(for: category).fill }
    }

    public static func tagLabel(for category: AlertCategory) -> Color {
        adaptive { $0.tagColors(for: category).label }
    }

    /// Corner radius shared by cards and glass panels.
    public static let cornerRadius: CGFloat = 16

    private static func adaptive(_ token: @escaping @Sendable (Palette) -> RGB) -> Color {
        #if canImport(UIKit)
        Color(
            UIColor { traits in
                UIColor(token(traits.userInterfaceStyle == .light ? .light : .dark))
            }
        )
        #elseif canImport(AppKit)
        Color(
            NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                return NSColor(token(isDark ? .dark : .light))
            }
        )
        #endif
    }
}

extension Palette {
    public func tagColors(for category: AlertCategory) -> TagColors {
        switch category {
        case .practice: practice
        case .qualifying: qualifying
        case .sprint: sprint
        case .race: race
        }
    }
}

#if canImport(UIKit)
extension UIColor {
    fileprivate convenience init(_ rgb: RGB) {
        self.init(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
    }
}
#elseif canImport(AppKit)
extension NSColor {
    fileprivate convenience init(_ rgb: RGB) {
        self.init(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
    }
}
#endif
