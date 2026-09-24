#if os(iOS)
import ActivityKit
import WidgetKit
import SwiftUI
import GridWalkKit

struct SessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            lockScreen(context: context)
                .padding()
                .activityBackgroundTint(Color(red: 0x0E / 255, green: 0x0F / 255, blue: 0x12 / 255))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.sessionShortName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startDate, style: .timer)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Color(red: 1, green: 0.23, blue: 0.19))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.weekendName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Text(context.state.sessionShortName)
                    .font(.caption.weight(.semibold))
            } compactTrailing: {
                Text(context.state.startDate, style: .timer)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color(red: 1, green: 0.23, blue: 0.19))
            } minimal: {
                Text(context.state.sessionShortName)
                    .font(.caption2.weight(.bold))
            }
        }
    }

    private func lockScreen(context: ActivityViewContext<SessionActivityAttributes>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.sessionDisplayName)
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.95, green: 0.95, blue: 0.95))
                Text(context.state.weekendName)
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.54, green: 0.56, blue: 0.60))
            }
            Spacer()
            Text(context.state.startDate, style: .timer)
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(Color(red: 1, green: 0.23, blue: 0.19))
        }
    }
}
#endif
