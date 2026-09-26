import GridWalkDesign
import GridWalkKit
import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            #if os(macOS)
            MenuBarSettingsSection(preferences: $model.preferences.menuBar)
            #endif

            FavoritesSection(model: model)

            SpoilerSettingsSection(model: model)

            Section("Alerts, 15 min before") {
                ForEach(AlertCategory.allCases, id: \.self) { category in
                    Toggle(isOn: alertBinding(category)) {
                        HStack(spacing: 8) {
                            SessionTag(category.sampleSession, size: .compact)
                            Text(category.displayName)
                        }
                    }
                }
            }

            Section("Data") {
                LabeledContent("Schedule") { FreshnessLabel(model.schedule.status) }
                LabeledContent("Standings") { FreshnessLabel(model.standings.status) }
                Button("Refresh now") {
                    Task { await model.refreshNow() }
                }
                .disabled(model.schedule.isRefreshing || model.standings.isRefreshing)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .screenBackground()
        #if os(macOS)
        .background { SettingsWindowAnchor() }
        #endif
        .tint(Theme.accent)
    }

    private func alertBinding(_ category: AlertCategory) -> Binding<Bool> {
        Binding(
            get: { model.preferences.alerts.enabled.contains(category) },
            set: { model.preferences.alerts.set(category, enabled: $0) }
        )
    }
}

private struct FavoritesSection: View {
    @Bindable var model: AppModel

    var body: some View {
        Section {
            Picker("Driver", selection: $model.preferences.favorites.driverCode) {
                Text("None").tag(String?.none)
                ForEach(OnboardingChoices.drivers(in: model.standings.snapshot)) { choice in
                    Text(choice.title).tag(Optional(choice.id))
                }
            }
            Picker("Team", selection: $model.preferences.favorites.constructorId) {
                Text("None").tag(String?.none)
                ForEach(OnboardingChoices.teams(in: model.standings.snapshot)) { choice in
                    Text(choice.title).tag(Optional(choice.id))
                }
            }
        } header: {
            Text("Favorites")
        } footer: {
            Text("Listed by name so picking doesn't give away the standings.")
        }
    }
}

extension AlertCategory {
    /// Any session in the group, just to draw its tag.
    fileprivate var sampleSession: SessionKind {
        switch self {
        case .practice: .practice1
        case .sprint: .sprint
        case .qualifying: .qualifying
        case .race: .race
        }
    }
}

#Preview("Settings") {
    let model = AppModel.preview()
    SettingsView(model: model).task { await model.start() }
}

#Preview("Settings, spoiler hidden") {
    let model = AppModel.preview(.resultsHidden)
    SettingsView(model: model).task { await model.start() }
}
