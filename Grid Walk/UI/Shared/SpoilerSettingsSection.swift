import GridWalkKit
import SwiftUI

struct SpoilerSettingsSection: View {
    @Bindable var model: AppModel

    var body: some View {
        Section {
            Toggle("Spoiler-free", isOn: $model.preferences.spoilers.isEnabled)
            if model.preferences.spoilers.isEnabled {
                Picker("Show results after", selection: $model.preferences.spoilers.revealDelay) {
                    ForEach(RevealDelay.allCases) { delay in
                        Text(delay.displayName).tag(delay)
                    }
                }
                TimelineView(.everyMinute) { context in
                    if let weekend = model.spoilerState(at: context.date).hiddenWeekend {
                        LabeledContent("Hidden", value: weekend.name)
                        Button("I've watched it, show results") {
                            model.revealResults(at: context.date)
                        }
                    }
                }
            }
        } header: {
            Text("Privacy")
        } footer: {
            Text(
                "Hides results, standings and your favorite's position in the app, menu bar and widgets until you mark the race watched or the delay passes."
            )
        }
    }
}
