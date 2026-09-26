#if os(iOS)
import GridWalkDesign
import GridWalkKit
import SwiftUI

/// Weekend tab: this weekend's timeline, then the whole season.
struct WeekendScreen: View {
    let model: AppModel

    var body: some View {
        TimelineView(.everyMinute) { context in
            ScrollView {
                VStack(spacing: 16) {
                    ScheduleGate(status: model.schedule.status, retry: refresh) {
                        content(now: context.date)
                    }
                }
                .padding()
            }
            .refreshable { await model.refreshNow() }
        }
        .screenBackground()
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if let weekend = model.hero(at: now).weekend {
            Card { WeekendTimelineView(weekend: weekend, now: now) }
        }
        let rows = SeasonOverview.rows(model.schedule.races, at: now)
        if rows.isEmpty {
            StateView(
                .empty(systemImage: "calendar"),
                title: Text("No calendar yet"),
                message: Text("The new calendar shows up here once it's out.")
            )
        } else {
            Card(Text("Season")) {
                SeasonListView(rows: rows)
            }
        }
    }

    private func refresh() {
        Task { await model.refreshNow() }
    }
}

private struct SeasonListView: View {
    let rows: [SeasonRow]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                HStack(spacing: 12) {
                    Text(row.weekend.round, format: .number)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(minWidth: 24, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.weekend.name)
                            .font(.subheadline.weight(row.status == .current ? .bold : .regular))
                            .foregroundStyle(row.status == .finished ? Theme.secondaryText : Theme.text)
                        Text(row.dates)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Spacer(minLength: 4)
                    if row.weekend.isSprintWeekend {
                        SessionTag(.sprint, size: .compact)
                    }
                    if row.status == .finished {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .padding(.vertical, 8)
                .overlay(alignment: .leading) {
                    if row.status == .current {
                        Capsule().fill(Theme.accent).frame(width: 4).offset(x: -10)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.accessibilityLabel)
                if row.id != rows.last?.id {
                    Divider().overlay(Theme.separator)
                }
            }
        }
    }
}

#Preview("Weekend") {
    let model = AppModel.preview()
    NavigationStack { WeekendScreen(model: model) }
        .task { await model.start() }
}

#Preview("Off-season") {
    let model = AppModel.preview(.offSeason)
    NavigationStack { WeekendScreen(model: model) }
        .task { await model.start() }
}

#Preview("Error") {
    let model = AppModel.preview(.failed)
    NavigationStack { WeekendScreen(model: model) }
        .task { await model.start() }
}
#endif
