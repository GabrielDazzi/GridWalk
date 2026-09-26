#if os(iOS)
import GridWalkDesign
import GridWalkKit
import SwiftUI

struct PhoneRootView: View {
    @Bindable var model: AppModel
    @State private var tab = LaunchOptions.initialTab.flatMap(PhoneTab.init(rawValue:)) ?? .countdown

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                CountdownScreen(model: model, openSettings: { tab = .settings })
                    .navigationTitle("Grid Walk")
            }
            .tabItem { Label("Countdown", systemImage: "timer") }
            .tag(PhoneTab.countdown)

            NavigationStack {
                WeekendScreen(model: model)
                    .navigationTitle("Weekend")
            }
            .tabItem { Label("Weekend", systemImage: "calendar") }
            .tag(PhoneTab.weekend)

            NavigationStack {
                StandingsView(model: model)
                    .navigationTitle("Standings")
            }
            .tabItem { Label("Standings", systemImage: "list.number") }
            .tag(PhoneTab.standings)

            NavigationStack {
                SettingsView(model: model)
                    .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(PhoneTab.settings)
        }
        .tint(Theme.accent)
        .fullScreenCover(isPresented: showsOnboarding) {
            OnboardingView(model: model)
        }
        .task { await model.run() }
    }

    private var showsOnboarding: Binding<Bool> {
        Binding(
            get: { !model.preferences.hasFinishedOnboarding },
            set: { model.preferences.hasFinishedOnboarding = !$0 }
        )
    }
}

enum PhoneTab: String, Hashable {
    case countdown
    case weekend
    case standings
    case settings
}

#Preview("Race weekend") {
    PhoneRootView(model: .preview())
}

#Preview("First launch") {
    PhoneRootView(model: .preview(.firstLaunch))
}
#endif
