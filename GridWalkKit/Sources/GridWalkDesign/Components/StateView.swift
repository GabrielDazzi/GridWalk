import GridWalkKit
import SwiftUI

/// Full-card placeholder for loading, empty, offline and error states.
public struct StateView: View {
    public enum Kind: Sendable {
        case loading
        case empty(systemImage: String)
        case error(FeedError)
    }

    private let kind: Kind
    private let title: Text
    private let message: Text?
    private let retry: (() -> Void)?

    public init(_ kind: Kind, title: Text, message: Text? = nil, retry: (() -> Void)? = nil) {
        self.kind = kind
        self.title = title
        self.message = message
        self.retry = retry
    }

    /// Standard error card: the error's own message plus a retry button.
    public static func failed(_ error: FeedError, title: Text? = nil, retry: @escaping () -> Void) -> StateView {
        StateView(
            .error(error),
            title: title ?? Text("Couldn't load the schedule", bundle: .module),
            message: Text(error.localizedDescription),
            retry: retry
        )
    }

    public var body: some View {
        Card {
            VStack(spacing: 12) {
                icon
                title
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                if let message {
                    message
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                if let retry {
                    Button(action: retry) {
                        Text("Try again", bundle: .module)
                    }
                    .buttonStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var icon: some View {
        switch kind {
        case .loading:
            ProgressView()
                .controlSize(.large)
                .tint(Theme.secondaryText)
        case .empty(let systemImage):
            symbol(systemImage)
        case .error(let error):
            symbol(error == .offline ? "wifi.slash" : "exclamationmark.triangle")
        }
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.title)
            .foregroundStyle(Theme.secondaryText)
            .accessibilityHidden(true)
    }
}

#Preview("States") {
    ScrollView {
        VStack(spacing: 16) {
            StateView(.loading, title: Text(verbatim: "Loading the season"))
            StateView(
                .empty(systemImage: "moon.stars"),
                title: Text(verbatim: "Off-season"),
                message: Text(verbatim: "The new calendar shows up here once it's out.")
            )
            StateView.failed(.offline) {}
            StateView.failed(.server(status: 503)) {}
        }
        .padding()
    }
    .screenBackground()
}
