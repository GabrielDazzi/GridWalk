#if os(iOS)
import ActivityKit
import Foundation

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

@MainActor
public enum SessionLiveActivity {
    public static func sync(with timed: TimedSession?, now: Date = .now) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            await endAll()
            return
        }

        guard let timed, LiveActivityPolicy.shouldShow(sessionStart: timed.session.dateUTC, now: now) else {
            await endAll()
            return
        }

        let state = LiveActivityPolicy.contentState(from: timed)
        let attributes = SessionActivityAttributes(sessionKindRaw: timed.session.kind.rawValue)

        if let existing = Activity<SessionActivityAttributes>.activities.first {
            await existing.update(.init(state: state, staleDate: timed.session.dateUTC))
            return
        }

        let content = ActivityContent(state: state, staleDate: timed.session.dateUTC)
        _ = try? Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
    }

    public static func endAll() async {
        for activity in Activity<SessionActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
#endif
