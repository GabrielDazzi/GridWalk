import Foundation

public enum StandingsMath {
    public static let postRaceGrace: TimeInterval = 3 * 60 * 60

    public static func needsRefresh(
        races: [RaceWeekend],
        cached: StandingsSnapshot?,
        now: Date = .now,
        postRaceGrace: TimeInterval = postRaceGrace
    ) -> Bool {
        guard let cached else { return true }
        guard let lastRaceEnd = lastCompletedRaceDate(in: races, now: now) else {
            return cached.drivers.isEmpty
        }
        let eligibleAt = lastRaceEnd.addingTimeInterval(postRaceGrace)
        return cached.fetchedAt < eligibleAt && now >= eligibleAt
    }

    public static func lastCompletedRaceDate(in races: [RaceWeekend], now: Date) -> Date? {
        races
            .compactMap { $0.sessions.first(where: { $0.kind == .race })?.dateUTC }
            .filter { $0 <= now }
            .max()
    }

    public static func remainingRaceWeekends(in races: [RaceWeekend], now: Date) -> Int {
        races.filter { weekend in
            guard let race = weekend.sessions.first(where: { $0.kind == .race }) else { return false }
            return race.dateUTC > now
        }.count
    }
}
