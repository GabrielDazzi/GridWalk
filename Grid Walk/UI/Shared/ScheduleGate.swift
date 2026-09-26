import GridWalkDesign
import GridWalkKit
import SwiftUI

/// Shows a loading or error card until the schedule exists, then the real content.
struct ScheduleGate<Content: View>: View {
    let status: FeedStatus
    let retry: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        switch status {
        case .loading:
            StateView(.loading, title: Text("Loading the season"))
        case .failed(let error):
            StateView.failed(error, retry: retry)
        case .ready, .stale:
            content()
        }
    }
}

#Preview("Loading") {
    ScheduleGate(status: .loading, retry: {}) { EmptyView() }
        .padding()
        .screenBackground()
}

#Preview("Error") {
    ScheduleGate(status: .failed(.offline), retry: {}) { EmptyView() }
        .padding()
        .screenBackground()
}
