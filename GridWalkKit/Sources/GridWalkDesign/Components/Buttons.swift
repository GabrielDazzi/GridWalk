import SwiftUI

/// Solid accent button for the one main action on a screen.
public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        StyledButton(configuration: configuration, isPrimary: true)
    }
}

/// Card-colored button with an accent label. Stays above 4.5:1, unlike the system tinted styles.
public struct SecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        StyledButton(configuration: configuration, isPrimary: false)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    public static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

private struct StyledButton: View {
    let configuration: ButtonStyleConfiguration
    let isPrimary: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let shape = Capsule()
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isPrimary ? Theme.onAccent : Theme.accent)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(isPrimary ? Theme.accent : Theme.card, in: shape)
            .overlay {
                if !isPrimary {
                    shape.strokeBorder(Theme.separator, lineWidth: 1)
                }
            }
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.75 : 1)
            // disabled controls are exempt from the contrast rule
            .opacity(isEnabled ? 1 : 0.45)
    }
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        Button {
        } label: {
            Text(verbatim: "Primary")
        }
        .buttonStyle(.primary)
        Button {
        } label: {
            Label {
                Text(verbatim: "Secondary, full width")
            } icon: {
                Image(systemName: "calendar.badge.plus")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.secondary)
        Button {
        } label: {
            Text(verbatim: "Disabled")
        }
        .buttonStyle(.primary)
        .disabled(true)
    }
    .padding()
    .screenBackground()
}
