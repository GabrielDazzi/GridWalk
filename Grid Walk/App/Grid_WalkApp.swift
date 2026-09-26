import GridWalkKit
import SwiftUI

@main
struct Grid_WalkApp: App {
    @State private var model = AppModel.forLaunch()

    init() {
        #if DEBUG && os(macOS)
        MacSnapshots.exportIfRequested()
        #endif
    }

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

        Window("Welcome", id: "onboarding") {
            OnboardingView(model: model)
                .frame(minWidth: 520, minHeight: 600)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView(model: model)
                .frame(width: 460, height: 620)
        }
        #else
        WindowGroup {
            PhoneRootView(model: model)
        }
        #endif
    }
}
