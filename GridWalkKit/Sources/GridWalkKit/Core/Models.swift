import Foundation

public struct Session: Identifiable, Codable, Sendable, Hashable {
    public var id: String { "\(kind.rawValue)-\(dateUTC.timeIntervalSince1970)" }

    public let kind: SessionKind
    /// Absolute instant; API times are UTC.
    public let dateUTC: Date

    public init(kind: SessionKind, dateUTC: Date) {
        self.kind = kind
        self.dateUTC = dateUTC
    }
}

public struct RaceWeekend: Identifiable, Codable, Sendable, Hashable {
    public var id: String { "\(season)-\(round)" }

    public let season: String
    public let round: Int
    public let name: String
    public let circuitName: String
    public let locality: String
    public let country: String
    public let sessions: [Session]

    public var isSprintWeekend: Bool {
        sessions.contains { $0.kind == .sprint || $0.kind == .sprintQualifying }
    }

    public init(
        season: String,
        round: Int,
        name: String,
        circuitName: String,
        locality: String,
        country: String,
        sessions: [Session]
    ) {
        self.season = season
        self.round = round
        self.name = name
        self.circuitName = circuitName
        self.locality = locality
        self.country = country
        self.sessions = sessions.sorted { $0.dateUTC < $1.dateUTC }
    }

    public func nextSession(after date: Date = .now) -> Session? {
        sessions.first { $0.dateUTC > date }
    }
}

public struct SeasonSchedule: Codable, Sendable, Hashable {
    public let season: String
    public let races: [RaceWeekend]
    public let fetchedAt: Date

    public init(season: String, races: [RaceWeekend], fetchedAt: Date = .now) {
        self.season = season
        self.races = races
        self.fetchedAt = fetchedAt
    }

    public func nextSession(after date: Date = .now) -> (weekend: RaceWeekend, session: Session)? {
        for race in races {
            if let session = race.nextSession(after: date) {
                return (race, session)
            }
        }
        return nil
    }

    public func currentWeekend(at date: Date = .now) -> RaceWeekend? {
        if let upcoming = nextSession(after: date)?.weekend {
            return upcoming
        }
        return races.last
    }
}

public struct TimedSession: Identifiable, Sendable, Hashable {
    public var id: String { "\(weekend.id)-\(session.id)" }
    public let weekend: RaceWeekend
    public let session: Session

    public init(weekend: RaceWeekend, session: Session) {
        self.weekend = weekend
        self.session = session
    }
}
