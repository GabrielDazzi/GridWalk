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
