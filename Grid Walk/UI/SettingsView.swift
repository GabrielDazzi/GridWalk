import SwiftUI
import GridWalkKit

struct SettingsView: View {
    @Binding var alertPrefs: AlertPreferences
    @Bindable var store: ScheduleStore

    var body: some View {
        Form {
            Section("Alerts (15 min before)") {
                ForEach(AlertCategory.allCases, id: \.self) { category in
                    Toggle(category.displayName, isOn: binding(for: category))
                }
            }

            Section("Schedule") {
                if let last = store.lastUpdated {
                    LabeledContent("Last updated", value: last.formatted(date: .abbreviated, time: .shortened))
                }
                Button("Refresh now") {
                    Task {
                        await store.refresh(force: true)
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
    }

    private func binding(for category: AlertCategory) -> Binding<Bool> {
        Binding(
            get: { alertPrefs.enabled.contains(category) },
            set: { alertPrefs.set(category, enabled: $0) }
        )
    }
}
