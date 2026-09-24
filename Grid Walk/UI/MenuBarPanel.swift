#if os(macOS)
import SwiftUI
import GridWalkKit
import AppKit

struct MenuBarLabel: View {
    @Bindable var store: ScheduleStore
    @State private var now = Date.now

    var body: some View {
        Group {
            if let next = store.nextSession {
                Text(CountdownFormat.menuBarLabel(session: next.session, from: now))
            } else {
                Text("Grid Walk")
            }
        }
        .onAppear {
            Task { await store.bootstrap() }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                now = .now
            }
        }
    }
}

struct MenuBarPanel: View {
    @Bindable var store: ScheduleStore
    @Binding var alertPrefs: AlertPreferences
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
