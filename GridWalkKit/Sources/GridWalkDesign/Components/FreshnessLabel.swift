import GridWalkKit
import SwiftUI

/// "Updated 5 min ago", or a warning line when the data is cached because the last refresh failed.
public struct FreshnessLabel: View {
    private let status: FeedStatus

    public init(_ status: FeedStatus) {
        self.status = status
    }

    public var body: some View {
        switch status {
        case .ready(let date):
            label(systemImage: "checkmark.circle", tint: Theme.secondaryText) {
                Text("Updated \(date, format: .relative(presentation: .named))", bundle: .module)
            }
        case .stale(let date, let error):
            label(systemImage: error == .offline ? "wifi.slash" : "exclamationmark.triangle", tint: Theme.accent) {
                if error == .offline {
                    Text("Offline, last updated \(date, format: .relative(presentation: .named))", bundle: .module)
                } else {
                    Text(
                        "Couldn't refresh, last updated \(date, format: .relative(presentation: .named))",
                        bundle: .module)
                }
            }
        case .loading:
            label(systemImage: "arrow.triangle.2.circlepath", tint: Theme.secondaryText) {
                Text("Loading", bundle: .module)
            }
        case .failed:
            EmptyView()
        }
    }

    private func label(systemImage: String, tint: Color, @ViewBuilder text: () -> some View) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            text()
                .foregroundStyle(Theme.secondaryText)
        }
        .font(.caption)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Freshness") {
    VStack(alignment: .leading, spacing: 12) {
        FreshnessLabel(.ready(lastUpdated: .now.addingTimeInterval(-300)))
        FreshnessLabel(.stale(lastUpdated: .now.addingTimeInterval(-86_400), error: .offline))
        FreshnessLabel(.stale(lastUpdated: .now.addingTimeInterval(-7_200), error: .server(status: 500)))
        FreshnessLabel(.loading)
    }
    .padding()
    .screenBackground()
}
