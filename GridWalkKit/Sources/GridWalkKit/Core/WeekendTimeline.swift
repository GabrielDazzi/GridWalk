import Foundation

/// Where a session sits relative to now.
public enum SessionPhase: Sendable, Hashable {
    case finished
    case live
    /// The first session that hasn't started yet.
    case next
    case later

    /// Past sessions are drawn dimmed.
    public var isPast: Bool { self == .finished }
}

/// One session in the weekend timeline, with its local day and time already formatted.
public struct TimelineRow: Identifiable, Sendable, Hashable {
    public var id: String { session.id }
    public let session: Session
    public let phase: SessionPhase
    /// e.g. "1:00 PM"
    public let time: String
    /// e.g. "Qualifying, Saturday, Mar 7, 1:00 PM, finished"
    public let accessibilityLabel: String
}

/// Sessions that fall on the same local day.
public struct TimelineDay: Identifiable, Sendable, Hashable {
    public var id: String { title }
    /// e.g. "Saturday, Mar 7"
    public let title: String
    public let rows: [TimelineRow]
}

/// What the hero countdown shows.
public enum HeroState: Sendable, Hashable {
    /// A session is running right now.
    case live(TimedSession)
    case upcoming(TimedSession)
    /// Every session this season is done, or the new calendar isn't out yet.
    case offSeason(lastWeekend: RaceWeekend?)

    /// Weekend to show in the timeline, nil in the off-season.
    public var weekend: RaceWeekend? {
        switch self {
        case .live(let timed), .upcoming(let timed): timed.weekend
        case .offSeason: nil
        }
    }
}

/// Builds the weekend timeline and the hero state. Days follow the user's time zone, not the track's.
public enum WeekendTimeline {
    public static func phase(of session: Session, in weekend: RaceWeekend, at now: Date) -> SessionPhase {
        let end = session.dateUTC.addingTimeInterval(session.kind.typicalDuration)
        if now >= end { return .finished }
        if now >= session.dateUTC { return .live }
        return weekend.nextSession(after: now) == session ? .next : .later
    }

    public static func days(
        for weekend: RaceWeekend,
        at now: Date,
        timeZone: TimeZone = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent
    ) -> [TimelineDay] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var days: [TimelineDay] = []
        var currentDay: Date?
        var bucket: [TimelineRow] = []

        func flush() {
            guard let currentDay, !bucket.isEmpty else { return }
            days.append(
                TimelineDay(
                    title: LocalTimeFormat.weekday(currentDay, timeZone: timeZone, locale: locale), rows: bucket)
            )
        }

        for session in weekend.sessions {
            let day = calendar.startOfDay(for: session.dateUTC)
            if day != currentDay {
                flush()
                currentDay = day
                bucket = []
            }
            bucket.append(row(for: session, in: weekend, at: now, timeZone: timeZone, locale: locale))
        }
        flush()
        return days
    }

    public static func hero(races: [RaceWeekend], at now: Date) -> HeroState {
        for weekend in races {
            for session in weekend.sessions {
                switch phase(of: session, in: weekend, at: now) {
                case .live: return .live(TimedSession(weekend: weekend, session: session))
                case .next: return .upcoming(TimedSession(weekend: weekend, session: session))
                case .finished, .later: continue
                }
            }
        }
        return .offSeason(lastWeekend: races.last)
    }

    private static func row(
        for session: Session,
        in weekend: RaceWeekend,
        at now: Date,
        timeZone: TimeZone,
        locale: Locale
    ) -> TimelineRow {
        let phase = phase(of: session, in: weekend, at: now)
        let when = LocalTimeFormat.sessionDateTime(session.dateUTC, timeZone: timeZone, locale: locale)
        let label =
            switch phase {
            case .finished: String(localized: "\(session.kind.displayName), \(when), finished", bundle: .module)
            case .live: String(localized: "\(session.kind.displayName), live now", bundle: .module)
            case .next: String(localized: "\(session.kind.displayName), \(when), up next", bundle: .module)
            case .later: "\(session.kind.displayName), \(when)"
            }
        return TimelineRow(
            session: session,
            phase: phase,
            time: LocalTimeFormat.sessionTime(session.dateUTC, timeZone: timeZone, locale: locale),
            accessibilityLabel: label
        )
    }
}
