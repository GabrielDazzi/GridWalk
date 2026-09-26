import GridWalkKit
import SwiftUI

@main
struct Grid_WalkApp: App {
    @State private var model = AppModel.live()

    var body: some Scene {
        #if os(macOS)
        MenuBarExtra {
            MenuBarPanel(model: model)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)

        Window("Standings", id: "standings") {
            StandingsView(model: model)
                .frame(minWidth: 360, minHeight: 480)
        }

        Settings {
            SettingsView(model: model)
                .frame(width: 420, height: 520)
        }
        #else
        WindowGroup {
            PhoneRootView(model: model)
        }
        #endif
    }
}
