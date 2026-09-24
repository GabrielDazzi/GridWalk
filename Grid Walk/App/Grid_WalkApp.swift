import SwiftUI
import GridWalkKit

@main
struct Grid_WalkApp: App {
    @State private var store = ScheduleStore.makeDefault()
    @State private var standings = StandingsStore.makeDefault()
    @State private var alertPrefs = AlertPreferencesStore().preferences
    @State private var menuBarPrefs = MenuBarPreferencesStore().preferences

    var body: some Scene {
        #if os(macOS)
        MenuBarExtra {
            MenuBarPanel(
                store: store,
                standings: standings,
                alertPrefs: $alertPrefs,
                menuBarPrefs: $menuBarPrefs
            )
        } label: {
            MenuBarLabel(
                store: store,
                standings: standings,
                menuBarPrefs: $menuBarPrefs
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(
                alertPrefs: $alertPrefs,
                menuBarPrefs: $menuBarPrefs,
                store: store,
                standings: standings
            )
            .frame(width: 420, height: 520)
        }
        #else
        WindowGroup {
            iOSRootView(
                store: store,
                standings: standings,
                alertPrefs: $alertPrefs,
                menuBarPrefs: $menuBarPrefs
            )
        }
        #endif
    }
}
