#if os(iOS)
import ActivityKit
import GridWalkDesign
import GridWalkKit
import SwiftUI
import WidgetKit

struct SessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            lockScreen(context: context)
                .padding()
                .activityBackgroundTint(Theme.background)
                .activitySystemActionForegroundColor(Theme.text)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    tag(context.attributes)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startDate, style: .timer)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Theme.accent)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(verbatim: "\(context.state.sessionDisplayName) · \(context.state.weekendName)")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            } compactLeading: {
                Text(context.state.sessionShortName)
                    .font(.caption.weight(.semibold))
            } compactTrailing: {
                Text(context.state.startDate, style: .timer)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.accent)
            } minimal: {
                Text(context.state.sessionShortName)
                    .font(.caption2.weight(.bold))
            }
        }
    }

    private func lockScreen(context: ActivityViewContext<SessionActivityAttributes>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    tag(context.attributes)
                    Text(context.state.sessionDisplayName)
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                }
                Text(context.state.weekendName)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Text(context.state.startDate, style: .timer)
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(Theme.accent)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    private func tag(_ attributes: SessionActivityAttributes) -> some View {
        if let kind = SessionKind(rawValue: attributes.sessionKindRaw) {
            SessionTag(kind)
        }
    }
}
#endif
