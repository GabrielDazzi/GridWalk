#if os(iOS)
import ActivityKit
import Foundation

/// Live Activity payload for the next session. Countdown only, never results.
public struct SessionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var sessionDisplayName: String
        public var sessionShortName: String
        public var weekendName: String
        public var startDate: Date

        public init(
            sessionDisplayName: String,
            sessionShortName: String,
            weekendName: String,
            startDate: Date
        ) {
            self.sessionDisplayName = sessionDisplayName
            self.sessionShortName = sessionShortName
            self.weekendName = weekendName
            self.startDate = startDate
        }
    }

    public var sessionKindRaw: String

    public init(sessionKindRaw: String) {
        self.sessionKindRaw = sessionKindRaw
    }
}

extension LiveActivityPolicy {
    public static func contentState(from timed: TimedSession) -> SessionActivityAttributes.ContentState {
        SessionActivityAttributes.ContentState(
            sessionDisplayName: timed.session.kind.displayName,
            sessionShortName: timed.session.kind.shortName,
            weekendName: timed.weekend.name,
            startDate: timed.session.dateUTC
        )
    }
}

/// ActivityKit backed controller.
@MainActor
public final class SessionLiveActivityController: LiveActivityControlling {
    public init() {}

    public func sync(with next: TimedSession?, now: Date) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled,
            let next,
            LiveActivityPolicy.shouldShow(sessionStart: next.session.dateUTC, now: now)
        else {
            await endAll()
            return
        }

        let state = LiveActivityPolicy.contentState(from: next)
        let content = ActivityContent(state: state, staleDate: next.session.dateUTC)
        if let existing = Activity<SessionActivityAttributes>.activities.first {
            await existing.update(content)
            return
        }
        _ = try? Activity.request(
            attributes: SessionActivityAttributes(sessionKindRaw: next.session.kind.rawValue),
            content: content,
            pushType: nil
        )
    }

    private func endAll() async {
        for activity in Activity<SessionActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
#endif
