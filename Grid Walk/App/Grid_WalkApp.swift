import SwiftUI
import GridWalkKit

@main
struct Grid_WalkApp: App {
    @State private var store = ScheduleStore.makeDefault()
    @State private var alertPrefs = AlertPreferencesStore().preferences

    var body: some Scene {
        #if os(macOS)
        MenuBarExtra {
            MenuBarPanel(store: store, alertPrefs: $alertPrefs)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(alertPrefs: $alertPrefs, store: store)
                .frame(width: 360, height: 280)
        }
        #else
        WindowGroup {
            iOSRootView(store: store, alertPrefs: $alertPrefs)
        }
        #endif
    }
}
