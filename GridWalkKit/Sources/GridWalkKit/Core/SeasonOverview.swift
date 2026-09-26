import Foundation

/// One weekend in the season list.
public struct SeasonRow: Identifiable, Sendable, Hashable {
    public enum Status: Sendable, Hashable {
        case finished
        /// The weekend with the next or live session.
        case current
        case upcoming
    }

    public var id: String { weekend.id }
    public let weekend: RaceWeekend
    public let status: Status
    /// e.g. "Mar 6 - 8" in the user's time zone.
    public let dates: String
    /// e.g. "Round 3, Bahrain Grand Prix, Mar 6 - 8, sprint weekend, finished"
    public let accessibilityLabel: String
}

/// The season calendar with each weekend marked finished, current or upcoming.
public enum SeasonOverview {
    public static func rows(
        _ races: [RaceWeekend],
        at now: Date,
        timeZone: TimeZone = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent
    ) -> [SeasonRow] {
        let currentID = currentWeekendID(races, at: now)
        return races.map { weekend in
            let status: SeasonRow.Status =
                if weekend.id == currentID {
                    .current
                } else if isFinished(weekend, at: now) {
                    .finished
                } else {
                    .upcoming
                }
            let dates = dateRange(of: weekend, timeZone: timeZone, locale: locale)
            return SeasonRow(
                weekend: weekend,
                status: status,
                dates: dates,
                accessibilityLabel: label(weekend, dates: dates, status: status)
            )
        }
    }

    /// Row to scroll to when the list appears.
    public static func scrollTarget(in rows: [SeasonRow]) -> SeasonRow.ID? {
        rows.first { $0.status == .current }?.id
    }

    static func isFinished(_ weekend: RaceWeekend, at now: Date) -> Bool {
        guard let last = weekend.sessions.last else { return false }
        return now >= last.dateUTC.addingTimeInterval(last.kind.typicalDuration)
    }

    private static func currentWeekendID(_ races: [RaceWeekend], at now: Date) -> RaceWeekend.ID? {
        WeekendTimeline.hero(races: races, at: now).weekend?.id
    }

    private static func dateRange(of weekend: RaceWeekend, timeZone: TimeZone, locale: Locale) -> String {
        guard let first = weekend.sessions.first?.dateUTC, let last = weekend.sessions.last?.dateUTC else {
            return ""
        }
        let style = Date.IntervalFormatStyle(locale: locale, timeZone: timeZone).month(.abbreviated).day()
        return (first..<max(first, last)).formatted(style)
    }

    private static func label(_ weekend: RaceWeekend, dates: String, status: SeasonRow.Status) -> String {
        var parts = [String(localized: "Round \(weekend.round)", bundle: .module), weekend.name, dates]
        if weekend.isSprintWeekend {
            parts.append(String(localized: "sprint weekend", bundle: .module))
        }
        switch status {
        case .finished: parts.append(String(localized: "finished", bundle: .module))
        case .current: parts.append(String(localized: "up next", bundle: .module))
        case .upcoming: break
        }
        return parts.joined(separator: ", ")
    }
}
