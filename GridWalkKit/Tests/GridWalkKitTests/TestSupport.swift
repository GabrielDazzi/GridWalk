import Foundation
import Testing

@testable import GridWalkKit

func fixture(_ name: String) throws -> Data {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

func makeWeekend(
    round: Int = 1,
    name: String = "Test Grand Prix",
    sessions: [Session]
) -> RaceWeekend {
    RaceWeekend(
        season: "2026",
        round: round,
        name: name,
        circuitName: "Test Circuit",
        locality: "Test",
        country: "Test",
        sessions: sessions
    )
}

func makeWeekend(round: Int = 1, raceAt: Date) -> RaceWeekend {
    makeWeekend(round: round, sessions: [Session(kind: .race, dateUTC: raceAt)])
}

func utcDate(_ text: String) throws -> Date {
    try #require(ISO8601DateFormatter().date(from: text))
}

func makeDriver(
    position: Int,
    points: Double,
    code: String,
    team: String = "team",
    wins: Int = 0
) -> DriverStanding {
    DriverStanding(
        position: position,
        points: points,
        wins: wins,
        driverId: code.lowercased(),
        code: code,
        givenName: code,
        familyName: code,
        constructorId: team,
        constructorName: team.capitalized
    )
}

func sampleStandings(lastRaceAt: Date? = nil, fetchedAt: Date = .now) -> StandingsSnapshot {
    let last: LastRaceResults? = lastRaceAt.map { date in
        LastRaceResults(
            season: "2026",
            round: 5,
            raceName: "Sample Grand Prix",
            dateUTC: date,
            results: [
                RaceResultEntry(
                    position: 1,
                    points: 25,
                    driverId: "antonelli",
                    code: "ANT",
                    givenName: "Andrea Kimi",
                    familyName: "Antonelli",
                    constructorId: "mercedes"
                )
            ]
        )
    }
    return StandingsSnapshot(
        season: "2026",
        round: 5,
        drivers: [
            DriverStanding(
                position: 1,
                points: 292,
                wins: 8,
                driverId: "antonelli",
                code: "ANT",
                givenName: "Andrea Kimi",
                familyName: "Antonelli",
                constructorId: "mercedes",
                constructorName: "Mercedes"
            ),
            DriverStanding(
                position: 2,
                points: 250,
                wins: 3,
                driverId: "other",
                code: "OTH",
                givenName: "Other",
                familyName: "Driver",
                constructorId: "other",
                constructorName: "Other"
            ),
        ],
        constructors: [
            ConstructorStanding(position: 1, points: 503, wins: 10, constructorId: "mercedes", name: "Mercedes"),
            ConstructorStanding(position: 2, points: 300, wins: 3, constructorId: "other", name: "Other"),
        ],
        lastRace: last,
        fetchedAt: fetchedAt
    )
}

/// Serves fixture files per endpoint, or a canned error.
struct FixtureFeed: FeedFetching {
    var files: [FeedEndpoint: String] = [
        .schedule: "current_season",
        .driverStandings: "driver_standings",
        .constructorStandings: "constructor_standings",
        .lastResults: "last_results",
    ]
    var failure: FeedError?

    func data(for endpoint: FeedEndpoint) async throws(FeedError) -> Data {
        if let failure { throw failure }
        guard let name = files[endpoint] else { throw .emptyResponse }
        do {
            return try fixture(name)
        } catch {
            throw .emptyResponse
        }
    }
}
