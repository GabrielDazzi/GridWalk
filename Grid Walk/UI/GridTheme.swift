import GridWalkKit
import SwiftUI

enum GridTheme {
    static let asphalt = Color(red: 0x0E / 255, green: 0x0F / 255, blue: 0x12 / 255)
    static let graphite = Color(red: 0x1A / 255, green: 0x1C / 255, blue: 0x21 / 255)
    static let startRed = Color(red: 0xFF / 255, green: 0x3B / 255, blue: 0x30 / 255)
    static let pitWhite = Color(red: 0xF2 / 255, green: 0xF2 / 255, blue: 0xF2 / 255)
    static let muted = Color(red: 0x8A / 255, green: 0x8F / 255, blue: 0x98 / 255)
    static let qualifying = Color(red: 0xFF / 255, green: 0xB0 / 255, blue: 0x20 / 255)
    static let sprint = Color(red: 0x32 / 255, green: 0xD2 / 255, blue: 0xF5 / 255)

    static func tagColor(for kind: SessionKind) -> Color {
        switch kind.alertCategory {
        case .practice: muted
        case .qualifying: qualifying
        case .sprint: sprint
        case .race: startRed
        }
    }

    /// Color-blind friendly short tags: FP / Q / S / R
    static func accessibilityTag(for kind: SessionKind) -> String {
        switch kind.alertCategory {
        case .practice: "FP"
        case .qualifying: "Q"
        case .sprint: "S"
        case .race: "R"
        }
    }
}

struct CountdownText: View {
    let date: Date
    let now: Date
    var size: CGFloat = 56

    private var secondsLeft: TimeInterval {
        max(0, date.timeIntervalSince(now))
    }

    private var inFinalStretch: Bool {
        secondsLeft > 0 && secondsLeft <= 10 * 60
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.1, paused: !inFinalStretch)) { context in
            let pulse = inFinalStretch && Int(context.date.timeIntervalSinceReferenceDate / 1.1) % 2 == 0
            Text(CountdownFormat.compact(until: date, from: now))
                .font(.system(size: size, weight: .bold, design: .monospaced))
                .foregroundStyle(GridTheme.startRed)
                .opacity(pulse ? 0.55 : 1)
        }
    }
}

struct SessionTagChip: View {
    let kind: SessionKind

    var body: some View {
        HStack(spacing: 4) {
            Text(GridTheme.accessibilityTag(for: kind))
                .font(.caption2.weight(.bold).monospaced())
            Text(kind.shortName)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(GridTheme.tagColor(for: kind))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(GridTheme.tagColor(for: kind).opacity(0.15), in: Capsule())
        .accessibilityLabel(kind.displayName)
    }
}
