#if os(macOS)
import AppKit
import GridWalkKit
import SwiftUI

struct MenuBarLabel: View {
    let model: AppModel
    @State private var tick = 0
    @State private var now = Date()
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let content = model.menuBarLabel(at: now, tick: tick)
        Group {
            if model.preferences.menuBar.compactStyle, let image = content.systemImage {
                Label(content.compactText, systemImage: image)
            } else {
                Text(model.preferences.menuBar.compactStyle ? content.compactText : content.text)
            }
        }
        // a flexible width makes the status item measure, resize, and measure again
        .fixedSize()
        .accessibilityLabel(model.menuBarAccessibilityLabel(at: now, tick: tick))
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
        .task {
            while !Task.isCancelled {
                let second = Calendar.current.component(.second, from: Date())
                try? await Task.sleep(for: .seconds(max(1, 60 - second)))
                now = Date()
            }
        }
    }
}
#endif
