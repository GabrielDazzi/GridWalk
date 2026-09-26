import Foundation

/// How long results stay hidden after the race if the user never marks it watched.
public enum RevealDelay: Int, Codable, Sendable, CaseIterable, Identifiable {
    case twelveHours = 12
    case oneDay = 24
    case twoDays = 48
    case threeDays = 72
    case oneWeek = 168

    public var id: Int { rawValue }

    public var interval: TimeInterval {
        TimeInterval(rawValue) * 3600
    }

    public var displayName: String {
        switch self {
        case .twelveHours: String(localized: "12 hours", bundle: .module)
        case .oneDay: String(localized: "1 day", bundle: .module)
        case .twoDays: String(localized: "2 days", bundle: .module)
        case .threeDays: String(localized: "3 days", bundle: .module)
        case .oneWeek: String(localized: "1 week", bundle: .module)
        }
    }
}

/// Spoiler-free settings.
public struct SpoilerPreferences: Codable, Sendable, Equatable {
    public var isEnabled: Bool
    public var revealDelay: RevealDelay
    /// `RaceWeekend.id`s the user marked as watched.
    public var watchedWeekendIDs: Set<String>

    public init(isEnabled: Bool = false, revealDelay: RevealDelay = .twoDays, watchedWeekendIDs: Set<String> = []) {
        self.isEnabled = isEnabled
        self.revealDelay = revealDelay
        self.watchedWeekendIDs = watchedWeekendIDs
    }
}

/// What spoiler-free mode is hiding right now.
public struct SpoilerState: Sendable, Equatable {
    /// The weekend whose results are hidden, or nil when nothing is.
    public let hiddenWeekend: RaceWeekend?
    /// When results show up on their own if the user does nothing.
    public let revealDate: Date?

    public static let visible = SpoilerState(hiddenWeekend: nil, revealDate: nil)

    public var isHidingResults: Bool { hiddenWeekend != nil }
}

/// The one rule for spoilers, shared by the app, menu bar and widget.
///
/// A weekend's results are hidden from the start of its first scoring session (sprint or race) until the
/// user marks it watched or `revealDelay` has passed since the race started. Only the latest such weekend
/// matters: its standings already include every earlier result.
public enum SpoilerPolicy {
    public static func state(races: [RaceWeekend], preferences: SpoilerPreferences, now: Date) -> SpoilerState {
        guard preferences.isEnabled,
            let weekend = latestScoredWeekend(in: races, now: now),
            !preferences.watchedWeekendIDs.contains(weekend.id),
            let revealDate = revealDate(for: weekend, delay: preferences.revealDelay),
            now < revealDate
        else {
            return .visible
        }
        return SpoilerState(hiddenWeekend: weekend, revealDate: revealDate)
    }

    /// Latest weekend where a sprint or race has already started.
    static func latestScoredWeekend(in races: [RaceWeekend], now: Date) -> RaceWeekend? {
        races
            .filter { weekend in weekend.sessions.contains { $0.kind.isScoring && $0.dateUTC <= now } }
            .max { firstScoringStart($0) < firstScoringStart($1) }
    }

    static func revealDate(for weekend: RaceWeekend, delay: RevealDelay) -> Date? {
        let scoring = weekend.sessions.filter(\.kind.isScoring)
        let anchor = scoring.first { $0.kind == .race } ?? scoring.last
        return anchor?.dateUTC.addingTimeInterval(delay.interval)
    }

    private static func firstScoringStart(_ weekend: RaceWeekend) -> Date {
        weekend.sessions.first(where: \.kind.isScoring)?.dateUTC ?? .distantPast
    }

    /// Watched ids after marking `weekend`, dropping ids that aren't in the current schedule.
    public static func watchedIDs(
        afterMarking weekend: RaceWeekend,
        in preferences: SpoilerPreferences,
        races: [RaceWeekend]
    ) -> Set<String> {
        let known = Set(races.map(\.id))
        return preferences.watchedWeekendIDs.intersection(known).union([weekend.id])
    }
}
