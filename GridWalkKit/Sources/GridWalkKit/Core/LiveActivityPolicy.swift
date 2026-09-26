import Foundation

/// When to surface a Live Activity for the next session (logic only; ActivityKit is iOS).
public enum LiveActivityPolicy {
    /// Start when the next session is within this window.
    public static let leadTime: TimeInterval = 6 * 60 * 60

    public static func shouldShow(sessionStart: Date, now: Date = .now) -> Bool {
        let remaining = sessionStart.timeIntervalSince(now)
        return remaining > 0 && remaining <= leadTime
    }
}

/// Starts, updates or ends the next-session Live Activity.
@MainActor
public protocol LiveActivityControlling: AnyObject {
    func sync(with next: TimedSession?, now: Date) async
}

/// Used on the Mac and anywhere Live Activities don't exist.
@MainActor
public final class NoLiveActivity: LiveActivityControlling {
    public init() {}

    public func sync(with next: TimedSession?, now: Date) async {}
}
