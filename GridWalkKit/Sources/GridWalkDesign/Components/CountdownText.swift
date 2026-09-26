import GridWalkKit
import SwiftUI

/// Live countdown to a session. Digits are monospaced so the layout doesn't jitter as they tick.
public struct CountdownText: View {
    public enum Style: Sendable {
        /// Big digit blocks with unit labels, for the home screen and popover.
        case hero
        /// One line like "1d 4h", for rows.
        case inline
    }

    private let target: Date
    private let kind: SessionKind
    private let style: Style

    public init(to target: Date, kind: SessionKind, style: Style = .hero) {
        self.target = target
        self.kind = kind
        self.style = style
    }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(now: context.date)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(CountdownFormat.accessibilityLabel(for: kind, until: target, from: context.date))
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        switch style {
        case .hero:
            HeroCountdown(parts: CountdownParts(until: target, from: now), secondsLeft: target.timeIntervalSince(now))
        case .inline:
            Text(CountdownFormat.compact(until: target, from: now))
                .monospacedDigit()
        }
    }
}

private struct HeroCountdown: View {
    let parts: CountdownParts
    let secondsLeft: TimeInterval

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var digitSize: CGFloat = 52

    // final ten minutes pulse, unless the user asked for less motion
    private var pulses: Bool { !reduceMotion && secondsLeft > 0 && secondsLeft <= 600 }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            blocks
            Text(verbatim: blocksAsText)
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(Theme.accent)
        }
        .phaseAnimator([false, true], trigger: pulses ? parts.seconds : -1) { view, dim in
            view.opacity(pulses && dim ? 0.6 : 1)
        } animation: { _ in
            .easeInOut(duration: 0.45)
        }
    }

    private var units: [(Int, LocalizedStringResource)] {
        if parts.days > 0 {
            return [
                (parts.days, LocalizedStringResource("DAYS", bundle: .module)),
                (parts.hours, LocalizedStringResource("HRS", bundle: .module)),
                (parts.minutes, LocalizedStringResource("MIN", bundle: .module)),
            ]
        }
        return [
            (parts.hours, LocalizedStringResource("HRS", bundle: .module)),
            (parts.minutes, LocalizedStringResource("MIN", bundle: .module)),
            (parts.seconds, LocalizedStringResource("SEC", bundle: .module)),
        ]
    }

    private var blocks: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            ForEach(Array(units.enumerated()), id: \.offset) { _, unit in
                VStack(spacing: 2) {
                    Text(unit.0, format: .number.precision(.integerLength(2...)))
                        .font(.system(size: digitSize, weight: .bold).monospacedDigit())
                        .foregroundStyle(Theme.accent)
                        .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
                        .animation(reduceMotion ? nil : .snappy, value: unit.0)
                    Text(unit.1)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .lineLimit(1)
    }

    private var blocksAsText: String {
        units.map { String(format: "%02d", $0.0) }.joined(separator: ":")
    }
}

#Preview("Countdown, days away") {
    VStack(alignment: .leading, spacing: 24) {
        CountdownText(to: .now.addingTimeInterval(100_000), kind: .qualifying)
        CountdownText(to: .now.addingTimeInterval(100_000), kind: .qualifying, style: .inline)
            .foregroundStyle(Theme.text)
    }
    .padding()
    .screenBackground()
}

#Preview("Countdown, final stretch") {
    CountdownText(to: .now.addingTimeInterval(420), kind: .race)
        .padding()
        .screenBackground()
}
