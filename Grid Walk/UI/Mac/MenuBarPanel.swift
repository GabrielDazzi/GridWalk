#if os(macOS)
import AppKit
import GridWalkDesign
import GridWalkKit
import SwiftUI

struct MenuBarPanel: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettingsAction

    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(spacing: 12) {
                PanelHeader(model: model, openSettings: openSettings)
                ScheduleGate(status: model.schedule.status, retry: refresh) {
                    content(now: context.date)
                }
                PanelFooter(model: model, now: context.date, openStandings: openStandings)
            }
        }
        .padding(12)
        .frame(width: 360)
        .screenBackground()
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let hero = model.hero(at: now)
        HeroCard(state: hero)
        if let weekend = hero.weekend {
            Card { WeekendTimelineView(weekend: weekend, now: now) }
        }
        FavoriteSnippetView(
            snippet: model.favoriteSnippet(at: now),
            onReveal: { model.revealResults(at: now) },
            onPick: openSettings
        )
    }

    private func refresh() {
        Task { await model.refreshNow() }
    }

    private func openStandings() {
        openWindow(id: "standings")
        NSApplication.shared.activate()
    }

    private func openSettings() {
        SettingsWindow.open(openSettingsAction.callAsFunction)
    }
}

private struct PanelHeader: View {
    let model: AppModel
    let openSettings: () -> Void

    var body: some View {
        HStack {
            Text(verbatim: "Grid Walk")
                .font(.headline)
                .foregroundStyle(Theme.text)
            Spacer()
            Button("Refresh", systemImage: "arrow.clockwise") {
                Task { await model.refreshNow() }
            }
            .disabled(model.schedule.isRefreshing)
            Button("Settings", systemImage: "gearshape", action: openSettings)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .foregroundStyle(Theme.secondaryText)
    }
}

private struct PanelFooter: View {
    let model: AppModel
    let now: Date
    let openStandings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let result = model.calendarResult {
                CalendarResultText(result: result)
            }
            HStack(spacing: 12) {
                FreshnessLabel(model.schedule.status)
                Spacer()
                Button("Add weekend to Calendar", systemImage: "calendar.badge.plus") {
                    guard let weekend = model.currentWeekend(at: now) else { return }
                    Task { await model.addToCalendar(weekend) }
                }
                .disabled(model.currentWeekend(at: now) == nil)
                Button("Standings", systemImage: "list.number", action: openStandings)
                Button("Quit", systemImage: "power") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .foregroundStyle(Theme.secondaryText)
        }
        .padding(.horizontal, 4)
    }
}

#Preview("Race weekend") {
    let model = AppModel.preview()
    MenuBarPanel(model: model).task { await model.start() }
}

#Preview("Spoiler hidden") {
    let model = AppModel.preview(.resultsHidden)
    MenuBarPanel(model: model).task { await model.start() }
}

#Preview("Offline") {
    let model = AppModel.preview(.offline)
    MenuBarPanel(model: model).task { await model.start() }
}

#Preview("Loading") {
    let model = AppModel.preview(.loading)
    MenuBarPanel(model: model).task { await model.start() }
}

#Preview("Error") {
    let model = AppModel.preview(.failed)
    MenuBarPanel(model: model).task { await model.start() }
}

#Preview("Off-season") {
    let model = AppModel.preview(.offSeason)
    MenuBarPanel(model: model).task { await model.start() }
}
#endif
