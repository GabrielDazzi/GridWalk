#if os(macOS)
import AppKit
import GridWalkKit
import SwiftUI

struct MenuBarPanel: View {
    let model: AppModel

    var body: some View {
        TimelineView(.everyMinute) { context in
            content(now: context.date)
        }
        .padding(14)
        .frame(width: 360)
        .background(GridTheme.asphalt)
        .preferredColorScheme(.dark)
    }

    private func content(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let next = model.nextSession(at: now) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(next.session.kind.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GridTheme.muted)
                    CountdownText(date: next.session.dateUTC, now: now, size: 36)
                    Text(next.weekend.name)
                        .font(.subheadline)
                        .foregroundStyle(GridTheme.pitWhite)
                }
            }

            if let weekend = model.currentWeekend(at: now) {
                WeekendHeader(weekend: weekend)
                SessionList(
                    weekend: weekend,
                    nextSessionID: model.nextSession(at: now)?.session.id,
                    now: now
                )
            } else if model.schedule.isRefreshing {
                ProgressView("Loading schedule…")
                    .tint(GridTheme.startRed)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                Text("No upcoming sessions")
                    .foregroundStyle(GridTheme.muted)
                    .frame(maxWidth: .infinity, minHeight: 80)
            }

            if let result = model.calendarResult {
                CalendarResultText(result: result)
            }

            Divider()
                .overlay(GridTheme.muted.opacity(0.35))

            HStack {
                Button("Refresh") {
                    Task { await model.refreshNow() }
                }
                .disabled(model.schedule.isRefreshing)

                Button("Add weekend to Calendar") {
                    guard let weekend = model.currentWeekend(at: now) else { return }
                    Task { await model.addToCalendar(weekend) }
                }
                .disabled(model.currentWeekend(at: now) == nil)

                Spacer()

                SettingsLink()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }
}

private struct WeekendHeader: View {
    let weekend: RaceWeekend

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(weekend.name)
                    .font(.headline)
                    .foregroundStyle(GridTheme.pitWhite)
                if weekend.isSprintWeekend {
                    Text("Sprint")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(GridTheme.sprint.opacity(0.2), in: Capsule())
                        .foregroundStyle(GridTheme.sprint)
                }
            }
            Text("\(weekend.circuitName) · \(weekend.locality)")
                .font(.caption)
                .foregroundStyle(GridTheme.muted)
        }
    }
}
#endif
