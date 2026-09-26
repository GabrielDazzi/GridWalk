#if os(macOS)
import GridWalkKit
import SwiftUI

struct MenuBarLabel: View {
    let model: AppModel
    @State private var tick = 0

    var body: some View {
        TimelineView(.everyMinute) { context in
            let content = model.menuBarLabel(at: context.date, tick: tick)
            if model.preferences.menuBar.compactStyle, let image = content.systemImage {
                Label(content.compactText, systemImage: image)
            } else {
                Text(model.preferences.menuBar.compactStyle ? content.compactText : content.text)
            }
        }
        // the label is always on screen, so it hosts the app's background loop
        .task { await model.run() }
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
