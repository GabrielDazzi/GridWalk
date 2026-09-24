import SwiftUI
import GridWalkKit

struct SettingsView: View {
    @Binding var alertPrefs: AlertPreferences
    @Binding var menuBarPrefs: MenuBarPreferences
    @Bindable var store: ScheduleStore
    @Bindable var standings: StandingsStore

    var body: some View {
        Form {
            #if os(macOS)
            Section("Menu bar") {
                Picker("Mode", selection: $menuBarPrefs.mode) {
                    ForEach(MenuBarMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Toggle("Compact style", isOn: $menuBarPrefs.compactStyle)

                Toggle("Ticker", isOn: $menuBarPrefs.tickerEnabled)
                if menuBarPrefs.tickerEnabled {
                    Text("Rotate up to 3 modes (not Auto)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(MenuBarMode.allCases.filter { $0 != .auto }) { mode in
                        Toggle(mode.displayName, isOn: tickerBinding(mode))
                    }
                }
            }
            #endif

            Section("Favorites") {
                Picker("Driver", selection: driverSelection) {
                    Text("None").tag(String?.none)
                    ForEach(standings.snapshot?.drivers ?? []) { driver in
                        Text("\(driver.displayCode) · \(driver.familyName)").tag(Optional(driver.displayCode))
                    }
                }
                Picker("Team", selection: teamSelection) {
                    Text("None").tag(String?.none)
                    ForEach(standings.snapshot?.constructors ?? []) { team in
                        Text(team.name).tag(Optional(team.constructorId))
                    }
                }
            }

            Section("Privacy") {
                Toggle("Spoiler-free", isOn: $menuBarPrefs.spoilerFree)
                Text("Hides last-race results in the menu bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Alerts (15 min before)") {
                ForEach(AlertCategory.allCases, id: \.self) { category in
                    Toggle(category.displayName, isOn: binding(for: category))
                }
            }

            Section("Schedule") {
                if let last = store.lastUpdated {
                    LabeledContent("Last updated", value: last.formatted(date: .abbreviated, time: .shortened))
                }
                if let standingsAt = standings.snapshot?.fetchedAt {
                    LabeledContent("Standings", value: standingsAt.formatted(date: .abbreviated, time: .shortened))
                }
                Button("Refresh now") {
                    Task {
                        await store.refresh(force: true)
                        await standings.refreshIfNeeded(races: store.allRaces, force: true)
                        await SessionNotifier.reschedule(races: store.allRaces, preferences: alertPrefs)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .scrollContentBackground(.hidden)
        .background(GridTheme.asphalt)
        .preferredColorScheme(.dark)
        .onChange(of: alertPrefs) { _, newValue in
            AlertPreferencesStore().preferences = newValue
            Task {
                await SessionNotifier.reschedule(races: store.allRaces, preferences: newValue)
            }
        }
        .onChange(of: menuBarPrefs) { _, newValue in
            MenuBarPreferencesStore().preferences = newValue
        }
    }

    private var driverSelection: Binding<String?> {
        Binding(
            get: { menuBarPrefs.favoriteDriverCode },
            set: { menuBarPrefs.favoriteDriverCode = $0 }
        )
    }

    private var teamSelection: Binding<String?> {
        Binding(
            get: { menuBarPrefs.favoriteConstructorId },
            set: { menuBarPrefs.favoriteConstructorId = $0 }
        )
    }

    private func binding(for category: AlertCategory) -> Binding<Bool> {
        Binding(
            get: { alertPrefs.enabled.contains(category) },
            set: { alertPrefs.set(category, enabled: $0) }
        )
    }

    private func tickerBinding(_ mode: MenuBarMode) -> Binding<Bool> {
        Binding(
            get: { menuBarPrefs.tickerModes.contains(mode) },
            set: { isOn in
                var modes = menuBarPrefs.tickerModes
                if isOn {
                    if !modes.contains(mode), modes.count < 3 {
                        modes.append(mode)
                    }
                } else {
                    modes.removeAll { $0 == mode }
                }
                menuBarPrefs.setTickerModes(modes)
            }
        )
    }
}
