#if os(iOS)
import GridWalkDesign
import GridWalkKit
import SwiftUI

/// Home tab: hero countdown, favorites, and a calendar shortcut.
struct CountdownScreen: View {
    let model: AppModel
    let openSettings: () -> Void

    var body: some View {
        TimelineView(.everyMinute) { context in
            ScrollView {
                VStack(spacing: 16) {
                    ScheduleGate(status: model.schedule.status, retry: refresh) {
                        content(now: context.date)
                    }
                    FreshnessLabel(model.schedule.status)
                }
                .padding()
            }
            .refreshable { await model.refreshNow() }
        }
        .screenBackground()
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let hero = model.hero(at: now)
        HeroCard(state: hero)
        FavoriteSnippetView(
            snippet: model.favoriteSnippet(at: now),
            onReveal: { model.revealResults(at: now) },
            onPick: openSettings
        )
        if let weekend = hero.weekend {
            VStack(spacing: 6) {
                Button {
                    Task { await model.addToCalendar(weekend) }
                } label: {
                    Label("Add weekend to Calendar", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)
                if let result = model.calendarResult {
                    CalendarResultText(result: result)
                }
            }
        }
    }

    private func refresh() {
        Task { await model.refreshNow() }
    }
}

#Preview("Race weekend") {
    let model = AppModel.preview()
    NavigationStack { CountdownScreen(model: model, openSettings: {}) }
        .task { await model.start() }
}

#Preview("Spoiler hidden") {
    let model = AppModel.preview(.resultsHidden)
    NavigationStack { CountdownScreen(model: model, openSettings: {}) }
        .task { await model.start() }
}

#Preview("Offline") {
    let model = AppModel.preview(.offline)
    NavigationStack { CountdownScreen(model: model, openSettings: {}) }
        .task { await model.start() }
}

#Preview("Loading") {
    let model = AppModel.preview(.loading)
    NavigationStack { CountdownScreen(model: model, openSettings: {}) }
        .task { await model.start() }
}

#Preview("Error") {
    let model = AppModel.preview(.failed)
    NavigationStack { CountdownScreen(model: model, openSettings: {}) }
        .task { await model.start() }
}

#Preview("Off-season") {
    let model = AppModel.preview(.offSeason)
    NavigationStack { CountdownScreen(model: model, openSettings: {}) }
        .task { await model.start() }
}
#endif
