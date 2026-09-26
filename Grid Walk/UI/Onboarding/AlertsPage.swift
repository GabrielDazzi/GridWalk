import GridWalkDesign
import GridWalkKit
import SwiftUI

/// Optional last step: pick alert types and ask for notification permission.
struct AlertsPage: View {
    @Bindable var model: AppModel
    @State private var permission: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session alerts")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.text)
            Text("A notification 15 minutes before each session you pick. Optional.")
                .foregroundStyle(Theme.secondaryText)
            Card {
                ForEach(AlertCategory.allCases, id: \.self) { category in
                    Toggle(category.displayName, isOn: binding(category))
                        .foregroundStyle(Theme.text)
                }
            }
            switch permission {
            case nil:
                Button {
                    Task { permission = await model.requestNotificationPermission() }
                } label: {
                    Label("Allow notifications", systemImage: "bell.badge")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)
            case true?:
                Label("Notifications are on", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Theme.text)
            case false?:
                Text("Notifications are off. You can turn them on later in System Settings.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private func binding(_ category: AlertCategory) -> Binding<Bool> {
        Binding(
            get: { model.preferences.alerts.enabled.contains(category) },
            set: { model.preferences.alerts.set(category, enabled: $0) }
        )
    }
}
