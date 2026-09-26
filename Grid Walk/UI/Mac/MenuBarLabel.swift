#if os(macOS)
import AppKit
import GridWalkKit
import SwiftUI

struct MenuBarLabel: View {
    let model: AppModel
    @State private var tick = 0
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        TimelineView(.everyMinute) { context in
            let content = model.menuBarLabel(at: context.date, tick: tick)
            Group {
                if model.preferences.menuBar.compactStyle, let image = content.systemImage {
                    Label(content.compactText, systemImage: image)
                } else {
                    Text(model.preferences.menuBar.compactStyle ? content.compactText : content.text)
                }
            }
            .accessibilityLabel(model.menuBarAccessibilityLabel(at: context.date, tick: tick))
        }
        // the label is always on screen, so it hosts the app's background loop
        .task {
            if !model.preferences.hasFinishedOnboarding {
                openWindow(id: "onboarding")
                NSApplication.shared.activate()
            }
            await model.run()
        }
        .task(id: model.preferences.menuBar) {
            guard model.preferences.menuBar.isTickerActive else { return }
            let seconds = max(2, model.preferences.menuBar.tickerIntervalSeconds)
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(seconds))
                tick += 1
            }
        }
    }
}
#endif
