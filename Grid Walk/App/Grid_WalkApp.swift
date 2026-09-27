import GridWalkKit
import SwiftUI

@main
struct Grid_WalkApp: App {
    @State private var model = AppModel.forLaunch()
    #if os(macOS)
    @State private var updates = MacUpdateCenter()
    #endif

    init() {
        #if DEBUG && os(macOS)
        MacSnapshots.exportIfRequested()
        #endif
    }

    var body: some Scene {
        #if os(macOS)
        MenuBarExtra {
            MenuBarPanel(model: model, updates: updates)
        } label: {
            MenuBarLabel(model: model, updates: updates)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appSettings) {
                SettingsMenuButton()
            }
        }

        Window("Standings", id: "standings") {
            StandingsView(model: model)
                .frame(minWidth: 360, minHeight: 480)
        }

        Window("Welcome", id: "onboarding") {
            OnboardingView(model: model)
                .frame(minWidth: 720, minHeight: 560)
        }
        .defaultSize(width: 720, height: 640)
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView(model: model, updates: updates)
                .frame(width: 460, height: 620)
        }
        #else
        WindowGroup {
            PhoneRootView(model: model)
        }
        #endif
    }
}
