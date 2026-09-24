#if os(macOS)
import SwiftUI
import GridWalkKit
import AppKit

struct MenuBarLabel: View {
    @Bindable var store: ScheduleStore
    @Bindable var standings: StandingsStore
    @Binding var menuBarPrefs: MenuBarPreferences

    @State private var now = Date.now
    @State private var tickerIndex = 0

    var body: some View {
        let content = currentContent
        Group {
            if menuBarPrefs.compactStyle {
                if let image = content.systemImage {
                    Label(content.compactText, systemImage: image)
                } else {
                    Text(content.compactText)
                }
            } else {
                Text(content.text)
            }
        }
        .onAppear {
            Task {
                await store.bootstrap()
                await standings.bootstrap(races: store.allRaces)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                now = .now
            }
        }
        .task(id: tickerTaskID) {
            guard menuBarPrefs.tickerEnabled, menuBarPrefs.tickerModes.count >= 2 else { return }
            while !Task.isCancelled {
                let seconds = max(2, menuBarPrefs.tickerIntervalSeconds)
                try? await Task.sleep(for: .seconds(seconds))
                tickerIndex = (tickerIndex + 1) % menuBarPrefs.tickerModes.count
            }
        }
    }

    private var tickerTaskID: String {
        "\(menuBarPrefs.tickerEnabled)-\(menuBarPrefs.tickerModes.map(\.rawValue).joined())-\(menuBarPrefs.tickerIntervalSeconds)"
    }

    private var activeMode: MenuBarMode {
        if menuBarPrefs.tickerEnabled, menuBarPrefs.tickerModes.count >= 2 {
            let modes = menuBarPrefs.tickerModes.filter { mode in
                !(mode == .lastRace && menuBarPrefs.spoilerFree)
            }
            guard !modes.isEmpty else { return menuBarPrefs.mode }
            return modes[tickerIndex % modes.count]
        }
        return menuBarPrefs.mode
    }

    private var currentContent: MenuBarLabelContent {
        MenuBarLabelFormatter.content(
            mode: activeMode,
            prefs: menuBarPrefs,
            nextSession: store.nextSession,
            races: store.allRaces,
            standings: standings.snapshot,
            now: now
        )
    }
}

struct MenuBarPanel: View {
    @Bindable var store: ScheduleStore
    @Bindable var standings: StandingsStore
    @Binding var alertPrefs: AlertPreferences
    @Binding var menuBarPrefs: MenuBarPreferences
    @State private var now = Date.now
    @State private var calendarMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let next = store.nextSession {
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

            if let weekend = store.currentWeekend {
                WeekendHeader(weekend: weekend)
                SessionList(
                    weekend: weekend,
                    nextSessionID: store.nextSession?.session.id,
                    now: now
                )
            } else if store.isRefreshing {
                ProgressView("Loading schedule…")
                    .tint(GridTheme.startRed)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                Text("No upcoming sessions")
                    .foregroundStyle(GridTheme.muted)
                    .frame(maxWidth: .infinity, minHeight: 80)
            }

            if let calendarMessage {
                Text(calendarMessage)
                    .font(.caption)
                    .foregroundStyle(GridTheme.muted)
            }

            Divider()
                .overlay(GridTheme.muted.opacity(0.35))

            HStack {
                Button("Refresh") {
                    Task {
                        await store.refresh(force: true)
                        await standings.refreshIfNeeded(races: store.allRaces, force: true)
                        await rescheduleAlerts()
                    }
                }
                .disabled(store.isRefreshing)

                Button("Add weekend to Calendar") {
                    Task { await addToCalendar() }
                }
                .disabled(store.currentWeekend == nil)

                Spacer()

                SettingsLink()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
        .padding(14)
        .frame(width: 360)
        .background(GridTheme.asphalt)
        .preferredColorScheme(.dark)
        .task {
            await store.bootstrap()
            await standings.bootstrap(races: store.allRaces)
            await rescheduleAlerts()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                now = .now
            }
        }
        .onChange(of: alertPrefs) { _, newValue in
            AlertPreferencesStore().preferences = newValue
            Task { await rescheduleAlerts() }
        }
        .onChange(of: menuBarPrefs) { _, newValue in
            MenuBarPreferencesStore().preferences = newValue
        }
    }

    private func rescheduleAlerts() async {
        _ = await SessionNotifier.requestAuthorization()
        await SessionNotifier.reschedule(races: store.allRaces, preferences: alertPrefs)
    }

    private func addToCalendar() async {
        guard let weekend = store.currentWeekend else { return }
        do {
            let count = try await WeekendCalendarExporter().addWeekend(weekend)
            calendarMessage = "Added \(count) events"
        } catch {
            calendarMessage = error.localizedDescription
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
