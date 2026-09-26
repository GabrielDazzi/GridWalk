#if os(macOS)
import GridWalkDesign
import GridWalkKit
import SwiftUI

struct MenuBarSettingsSection: View {
    @Binding var preferences: MenuBarPreferences

    var body: some View {
        Section("Menu bar") {
            Picker("Mode", selection: $preferences.mode) {
                ForEach(MenuBarMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            Toggle("Compact style", isOn: $preferences.compactStyle)

            Toggle("Ticker", isOn: $preferences.tickerEnabled)
            if preferences.tickerEnabled {
                Text("Rotate up to 3 modes (not Auto)")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                ForEach(MenuBarMode.allCases.filter { $0 != .auto }) { mode in
                    Toggle(mode.displayName, isOn: tickerBinding(mode))
                }
            }
        }
    }

    private func tickerBinding(_ mode: MenuBarMode) -> Binding<Bool> {
        Binding(
            get: { preferences.tickerModes.contains(mode) },
            set: { preferences.setTicker(mode, included: $0) }
        )
    }
}
#endif
