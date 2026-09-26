#if os(macOS)
import GridWalkDesign
import GridWalkKit
import SwiftUI

struct UpdateOfferRow: View {
    let updates: MacUpdateCenter

    var body: some View {
        if let release = updates.release, updates.phase == .ready || updates.phase == .failed {
            HStack(alignment: .firstTextBaseline) {
                Text("Update \(release.tag) is ready")
                    .font(.caption)
                    .foregroundStyle(Theme.text)
                Spacer()
                Group {
                    if updates.phase == .failed {
                        Button("Try again") { Task { await updates.install() } }
                    } else {
                        Button("Update") { Task { await updates.install() } }
                    }
                }
                .font(.caption.weight(.semibold))
                .disabled(!MacUpdateCenter.canReplaceThisCopy)
            }
        } else if updates.phase == .downloading || updates.phase == .installing {
            Text("Installing the update…")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
    }
}

struct UpdateSettingsSection: View {
    @Bindable var model: AppModel
    let updates: MacUpdateCenter

    var body: some View {
        Section {
            Toggle("Check for updates", isOn: $model.preferences.checksForAppUpdates)
            if updates.phase == .checking {
                Text("Checking GitHub…")
            } else if let release = updates.release, updates.phase != .idle {
                Text("Version \(release.tag) is available.")
                installButton
                    .disabled(installBlocked)
            } else if updates.phase == .failed {
                Text("Couldn't check for updates.")
                Button("Try again") {
                    Task { await updates.checkNow() }
                }
            } else {
                Button("Check now") {
                    Task { await updates.checkNow() }
                }
            }
        } header: {
            Text("Updates")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Direct Mac builds download the latest release and replace this app. Preferences stay.")
                Text("App Store copies update from the store, and Homebrew copies use brew upgrade.")
            }
        }
    }

    private var installBlocked: Bool {
        !MacUpdateCenter.canReplaceThisCopy
            || updates.phase == .downloading
            || updates.phase == .installing
    }

    @ViewBuilder
    private var installButton: some View {
        switch updates.phase {
        case .downloading, .installing:
            Button("Installing…") { Task { await updates.install() } }
        case .failed:
            Button("Try again") { Task { await updates.install() } }
        default:
            Button("Download and install") { Task { await updates.install() } }
        }
    }
}
#endif
