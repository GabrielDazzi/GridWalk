import GridWalkKit
import SwiftUI

@main
struct Grid_WalkApp: App {
    @State private var store = ScheduleStore.live()
    @State private var standings = StandingsStore.live()
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
            PhoneRootView(
                store: store,
                standings: standings,
                alertPrefs: $alertPrefs,
                menuBarPrefs: $menuBarPrefs
            )
        }
        #endif
    }
}
