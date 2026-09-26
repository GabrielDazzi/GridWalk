import GridWalkDesign
import GridWalkKit
import SwiftUI

/// A weekend's sessions grouped by local day. Finished sessions are dimmed, the next one stands out.
struct WeekendTimelineView: View {
    let weekend: RaceWeekend
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            WeekendHeader(weekend: weekend)
            ForEach(WeekendTimeline.days(for: weekend, at: now)) { day in
                VStack(alignment: .leading, spacing: 6) {
                    Text(day.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(day.rows) { row in
                        TimelineRowView(row: row)
                    }
                }
            }
        }
    }
}

struct WeekendHeader: View {
    let weekend: RaceWeekend

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(weekend.name)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                if weekend.isSprintWeekend {
                    Text("Sprint weekend")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(Capsule().strokeBorder(Theme.separator))
                }
            }
            Text(verbatim: "\(weekend.circuitName) · \(weekend.locality)")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TimelineRowView: View {
    let row: TimelineRow

    var body: some View {
        HStack(spacing: 10) {
            Text(row.time)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(row.phase.isPast ? Theme.secondaryText : Theme.text)
                .frame(minWidth: 64, alignment: .leading)
            // dimmed with the secondary color, not opacity, so past rows stay above 4.5:1
            SessionTag(row.session.kind, size: .compact)
            Text(row.session.kind.displayName)
                .font(.subheadline.weight(row.phase == .next ? .bold : .regular))
                .foregroundStyle(row.phase.isPast ? Theme.secondaryText : Theme.text)
            Spacer(minLength: 4)
            trailing
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background {
            if row.phase == .next || row.phase == .live {
                RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Theme.accent, lineWidth: 1.5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
    }

    @ViewBuilder
    private var trailing: some View {
        switch row.phase {
        case .finished:
            Image(systemName: "checkmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
        case .live:
            Text("Live")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.accent)
                .textCase(.uppercase)
        case .next:
            CountdownText(to: row.session.dateUTC, kind: row.session.kind, style: .inline)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
        case .later:
            EmptyView()
        }
    }
}

#Preview("Sprint weekend") {
    let weekend = SampleData.schedule(around: .now).races[2]
    ScrollView {
        Card { WeekendTimelineView(weekend: weekend, now: .now) }
            .padding()
    }
    .screenBackground()
}
