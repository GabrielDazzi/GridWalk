#if os(macOS)
import AppKit
import SwiftUI

// SwiftUI opens Settings but leaves it behind whichever window is already key
@MainActor
enum SettingsWindow {
    static weak var window: NSWindow?

    static func open(_ action: () -> Void) {
        NSApp.activate(ignoringOtherApps: true)
        action()
        Task { await bringForward() }
    }

    private static func bringForward() async {
        for _ in 0..<12 {
            if let window {
                window.makeKeyAndOrderFront(nil)
                return
            }
            try? await Task.sleep(for: .milliseconds(25))
        }
    }
}

struct SettingsWindowAnchor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ view: NSView, context: Context) {
        Task { @MainActor in
            if let window = view.window {
                SettingsWindow.window = window
            }
        }
    }
}

struct SettingsMenuButton: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Settings…") {
            SettingsWindow.open(openSettings.callAsFunction)
        }
        .keyboardShortcut(",", modifiers: .command)
    }
}
#endif
