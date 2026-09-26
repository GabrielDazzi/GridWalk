import GridWalkKit
import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            #if os(macOS)
            Section("Menu bar") {
                Picker("Mode", selection: $model.preferences.menuBar.mode) {
                    ForEach(MenuBarMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Toggle("Compact style", isOn: $model.preferences.menuBar.compactStyle)

                Toggle("Ticker", isOn: $model.preferences.menuBar.tickerEnabled)
                if model.preferences.menuBar.tickerEnabled {
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
                Picker("Driver", selection: $model.preferences.favorites.driverCode) {
                    Text("None").tag(String?.none)
                    ForEach(model.standings.snapshot?.drivers ?? []) { driver in
                        Text("\(driver.displayCode) · \(driver.familyName)").tag(Optional(driver.displayCode))
                    }
                }
                Picker("Team", selection: $model.preferences.favorites.constructorId) {
                    Text("None").tag(String?.none)
                    ForEach(model.standings.snapshot?.constructors ?? []) { team in
                        Text(team.name).tag(Optional(team.constructorId))
                    }
                }
            }

            Section("Privacy") {
                Toggle("Spoiler-free", isOn: $model.preferences.spoilerFree)
                Text("Hides last-race results in the menu bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Alerts (15 min before)") {
                ForEach(AlertCategory.allCases, id: \.self) { category in
                    Toggle(category.displayName, isOn: alertBinding(category))
                }
            }

            Section("Schedule") {
                if let last = model.schedule.lastUpdated {
                    LabeledContent("Last updated", value: last.formatted(date: .abbreviated, time: .shortened))
                }
                if let standingsAt = model.standings.snapshot?.fetchedAt {
                    LabeledContent("Standings", value: standingsAt.formatted(date: .abbreviated, time: .shortened))
                }
                Button("Refresh now") {
                    Task { await model.refreshNow() }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .scrollContentBackground(.hidden)
        .background(GridTheme.asphalt)
        .preferredColorScheme(.dark)
    }

    private func alertBinding(_ category: AlertCategory) -> Binding<Bool> {
        Binding(
            get: { model.preferences.alerts.enabled.contains(category) },
            set: { model.preferences.alerts.set(category, enabled: $0) }
        )
    }

    private func tickerBinding(_ mode: MenuBarMode) -> Binding<Bool> {
        Binding(
            get: { model.preferences.menuBar.tickerModes.contains(mode) },
            set: { model.preferences.menuBar.setTicker(mode, included: $0) }
        )
    }
}
