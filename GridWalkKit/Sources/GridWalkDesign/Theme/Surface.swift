import SwiftUI

extension View {
    /// Card background: Liquid Glass on OS 26, a solid card color before that or with Reduce Transparency.
    public func cardSurface(cornerRadius: CGFloat = Theme.cornerRadius) -> some View {
        modifier(CardSurface(cornerRadius: cornerRadius))
    }

    /// Full-bleed screen background.
    public func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }
}

extension EnvironmentValues {
    /// Forces the solid card fallback even where Liquid Glass is available. Offscreen renderers need it.
    @Entry public var prefersSolidSurfaces = false
}

private struct CardSurface: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.prefersSolidSurfaces) private var prefersSolidSurfaces

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26, macOS 26, *), !reduceTransparency, !prefersSolidSurfaces {
            // tinted with the card color so text contrast doesn't depend on what's behind the glass
            content.glassEffect(.regular.tint(Theme.card.opacity(0.7)), in: shape)
        } else {
            content
                .background(Theme.card, in: shape)
                .overlay(shape.strokeBorder(Theme.separator, lineWidth: 1))
        }
    }
}
