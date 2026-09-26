import Foundation

/// Time left until a session, split into whole units. Always based on absolute seconds, so DST
/// changes and time zones never skew it.
public struct CountdownParts: Sendable, Equatable {
    public let days: Int
    public let hours: Int
    public let minutes: Int
    public let seconds: Int

    public init(until date: Date, from now: Date) {
        let total = max(0, Int(date.timeIntervalSince(now)))
        days = total / 86_400
        hours = (total % 86_400) / 3_600
        minutes = (total % 3_600) / 60
        seconds = total % 60
    }

    public var isFinished: Bool {
        days == 0 && hours == 0 && minutes == 0 && seconds == 0
    }
}

/// Countdown strings for labels and VoiceOver.
public enum CountdownFormat {
    /// e.g. "1d 4h", "3h 12m", "42m"
    public static func compact(until date: Date, from now: Date = .now) -> String {
        let parts = CountdownParts(until: date, from: now)
        if parts.days > 0 {
            return String(
                localized: "\(parts.days)d \(parts.hours)h", bundle: .module, comment: "Countdown, days and hours")
        }
        if parts.hours > 0 {
            return String(
                localized: "\(parts.hours)h \(parts.minutes)m",
                bundle: .module,
                comment: "Countdown, hours and minutes"
            )
        }
        return String(localized: "\(parts.minutes)m", bundle: .module, comment: "Countdown, minutes")
    }

    public static func menuBarLabel(session: Session, from now: Date = .now) -> String {
        "\(session.kind.shortName) · \(compact(until: session.dateUTC, from: now))"
    }

    /// Spelled-out duration, e.g. "1 day, 4 hours". Two largest units only.
    public static func spokenDuration(until date: Date, from now: Date, locale: Locale = .autoupdatingCurrent) -> String
    {
        let parts = CountdownParts(until: date, from: now)
        let formatter = DateComponentsFormatter()
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        formatter.calendar = calendar
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .dropAll
        formatter.allowedUnits = parts.days > 0 ? [.day, .hour] : [.hour, .minute]
        let components = DateComponents(day: parts.days, hour: parts.hours, minute: parts.minutes)
        return formatter.string(from: components) ?? compact(until: date, from: now)
    }

    /// VoiceOver label, e.g. "Qualifying in 1 day, 4 hours".
    public static func accessibilityLabel(for kind: SessionKind, until date: Date, from now: Date) -> String {
        guard date.timeIntervalSince(now) >= 60 else {
            return String(localized: "\(kind.displayName) is starting now", bundle: .module)
        }
        let duration = spokenDuration(until: date, from: now)
        return String(localized: "\(kind.displayName) in \(duration)", bundle: .module)
    }
}
