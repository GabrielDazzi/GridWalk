#if os(iOS)
import SwiftUI
import GridWalkKit

struct PhoneRootView: View {
    @Bindable var store: ScheduleStore
    @Bindable var standings: StandingsStore
    @Binding var alertPrefs: AlertPreferences
    @Binding var menuBarPrefs: MenuBarPreferences
    @State private var now = Date.now
    @State private var showSettings = false
    @State private var calendarMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if let next = store.nextSession(at: now) {
                        VStack(alignment: .leading, spacing: 10) {
                            SessionTagChip(kind: next.session.kind)
                            Text(next.session.kind.displayName)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(GridTheme.pitWhite)
                            CountdownText(date: next.session.dateUTC, now: now, size: 64)
                            Text(next.weekend.name)
                                .foregroundStyle(GridTheme.muted)
                            Text(LocalTimeFormat.sessionDateTime(next.session.dateUTC))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(GridTheme.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(GridTheme.graphite, in: RoundedRectangle(cornerRadius: 14))
                    } else {
                        Text("No upcoming sessions")
                            .foregroundStyle(GridTheme.muted)
                    }

                    if let weekend = store.currentWeekend(at: now) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Weekend")
                                    .font(.headline)
                                    .foregroundStyle(GridTheme.pitWhite)
                                if weekend.isSprintWeekend {
                                    Text("Sprint")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(GridTheme.sprint.opacity(0.2), in: Capsule())
                                        .foregroundStyle(GridTheme.sprint)
                                }
                            }
                            Text("\(weekend.circuitName) · \(weekend.locality)")
                                .font(.caption)
                                .foregroundStyle(GridTheme.muted)

                            SessionList(
                                weekend: weekend,
                                nextSessionID: store.nextSession(at: now)?.session.id,
                                now: now
                            )
                        }

                        Button("Add weekend to Calendar") {
                            Task { await addToCalendar(weekend) }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(GridTheme.startRed)
                    }

                    if let calendarMessage {
                        Text(calendarMessage)
                            .font(.caption)
                            .foregroundStyle(GridTheme.muted)
                    }
                }
                .padding()
            }
            .background(GridTheme.asphalt.ignoresSafeArea())
            .navigationTitle("Grid Walk")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        showSettings = true
                    }
                    .tint(GridTheme.pitWhite)
                }
            }
            .toolbarBackground(GridTheme.asphalt, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView(
                        alertPrefs: $alertPrefs,
                        menuBarPrefs: $menuBarPrefs,
                        store: store,
                        standings: standings
                    )
                    .navigationTitle("Settings")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSettings = false }
                        }
                    }
                }
                .preferredColorScheme(.dark)
            }
            .task {
                await store.bootstrap()
                await standings.bootstrap(races: store.races)
                _ = await SessionNotifier.requestAuthorization()
                await SessionNotifier.reschedule(races: store.races, preferences: alertPrefs)
                await SessionLiveActivity.sync(with: store.nextSession(at: now))
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(30))
                    now = .now
                    await SessionLiveActivity.sync(with: store.nextSession(at: now), now: now)
                }
            }
            .onChange(of: store.nextSession(at: now)) { _, newValue in
                Task { await SessionLiveActivity.sync(with: newValue) }
            }
            .onChange(of: alertPrefs) { _, newValue in
                AlertPreferencesStore().preferences = newValue
                Task {
                    await SessionNotifier.reschedule(races: store.races, preferences: newValue)
                }
            }
        }
    }

    private func addToCalendar(_ weekend: RaceWeekend) async {
        do {
            let count = try await WeekendCalendarExporter().addWeekend(weekend)
            calendarMessage = "Added \(count) events"
        } catch {
            calendarMessage = error.localizedDescription
        }
    }
}
#endif
