import Foundation
import Testing

@testable import GridWalkKit

@Suite("Standings decoding")
struct StandingsDecodingTests {
    @Test("parses driver standings")
    func drivers() throws {
        let data = try fixture("driver_standings")
        let decoded = try StandingsDecoder.decodeDrivers(data)
        #expect(!decoded.drivers.isEmpty)
        let leader = try #require(decoded.drivers.first)
        #expect(leader.position == 1)
        #expect(!leader.displayCode.isEmpty)
    }

    @Test("parses constructor standings")
    func constructors() throws {
        let data = try fixture("constructor_standings")
        let decoded = try StandingsDecoder.decodeConstructors(data)
        #expect(!decoded.constructors.isEmpty)
        #expect(decoded.constructors.first?.position == 1)
    }

    @Test("parses last race results")
    func lastResults() throws {
        let data = try fixture("last_results")
        let last = try StandingsDecoder.decodeLastResults(data)
        #expect(!last.results.isEmpty)
        #expect(last.winner?.position == 1)
    }
}

@Suite("Standings refresh")
struct StandingsRefreshTests {
    @Test("needs refresh when cache is before last race")
    func cacheStale() throws {
        let raceDate = Date(timeIntervalSince1970: 2_000_000)
        let races = [makeWeekend(raceAt: raceDate)]
        let cached = StandingsSnapshot(
            season: "2026",
            round: 1,
            drivers: [],
            constructors: [],
            lastRace: nil,
            fetchedAt: raceDate.addingTimeInterval(-3600)
        )
        let now = raceDate.addingTimeInterval(4 * 3600)
        #expect(StandingsMath.needsRefresh(races: races, cached: cached, now: now))
    }

    @Test("skips refresh when cache is fresh after race")
    func cacheFresh() throws {
        let raceDate = Date(timeIntervalSince1970: 2_000_000)
        let races = [makeWeekend(raceAt: raceDate)]
        let cached = StandingsSnapshot(
            season: "2026",
            round: 1,
            drivers: [
                DriverStanding(
                    position: 1, points: 10, wins: 1,
                    driverId: "x", code: "XXX",
                    givenName: "A", familyName: "B",
                    constructorId: "c", constructorName: "C"
                )
            ],
            constructors: [],
            lastRace: nil,
            fetchedAt: raceDate.addingTimeInterval(4 * 3600)
        )
        let now = raceDate.addingTimeInterval(5 * 3600)
        #expect(!StandingsMath.needsRefresh(races: races, cached: cached, now: now))
    }
}

@Suite("Menu bar formatter")
struct MenuBarFormatterTests {
    @Test("formats my driver")
    func myDriver() {
        let prefs = MenuBarPreferences(favoriteDriverCode: "ANT")
        let standings = sampleStandings()
        let content = MenuBarLabelFormatter.format(
            mode: .myDriver,
            prefs: prefs,
            nextSession: nil,
            races: [],
            standings: standings
        )
        #expect(content?.text.contains("ANT") == true)
        #expect(content?.text.contains("P1") == true)
    }

    @Test("title fight shows gap")
    func titleFightGap() {
        let standings = sampleStandings()
        let raceFuture = Date().addingTimeInterval(30 * 24 * 3600)
        // Enough remaining races so we show a plain gap, not "still in the fight"
        let races = (0..<6).map { i in
            makeWeekend(raceAt: raceFuture.addingTimeInterval(Double(i) * 14 * 24 * 3600))
        }
        let content = MenuBarLabelFormatter.titleFight(standings: standings, races: races, now: .now)
        #expect(content.text.hasPrefix("+") || content.text == "0")
    }

    @Test("title fight champion when gap exceeds points left")
    func titleFightChampion() {
        let standings = StandingsSnapshot(
            season: "2026",
            round: 20,
            drivers: [
                DriverStanding(
                    position: 1, points: 400, wins: 10, driverId: "a", code: "AAA", givenName: "A", familyName: "A",
                    constructorId: "c", constructorName: "C"),
                DriverStanding(
                    position: 2, points: 300, wins: 2, driverId: "b", code: "BBB", givenName: "B", familyName: "B",
                    constructorId: "d", constructorName: "D"),
            ],
            constructors: [],
            lastRace: nil
        )
        // One race left = 25 points; gap 100 => champion
        let raceFuture = Date().addingTimeInterval(7 * 24 * 3600)
        let races = [makeWeekend(raceAt: raceFuture)]
        let content = MenuBarLabelFormatter.titleFight(standings: standings, races: races, now: .now)
        #expect(content.text == "Champion")
    }

    @Test("spoiler-free hides last race")
    func spoilerHidesLastRace() {
        let prefs = MenuBarPreferences(spoilerFree: true)
        let content = MenuBarLabelFormatter.format(
            mode: .lastRace,
            prefs: prefs,
            nextSession: nil,
            races: [],
            standings: sampleStandings()
        )
        #expect(content == nil)
    }

    @Test("auto picks countdown on race weekend")
    func autoWeekend() {
        let start = Date().addingTimeInterval(2 * 3600)
        let timed = TimedSession(
            weekend: makeWeekend(raceAt: start.addingTimeInterval(2 * 24 * 3600)),
            session: Session(kind: .qualifying, dateUTC: start)
        )
        let resolved = MenuBarLabelFormatter.resolveMode(
            .auto,
            prefs: MenuBarPreferences(),
            nextSession: timed,
            races: [],
            standings: sampleStandings(),
            now: .now
        )
        #expect(resolved == .countdown)
    }

    @Test("auto picks last race after race when not spoiler-free")
    func autoPostRace() {
        let lastDate = Date().addingTimeInterval(-2 * 3600)
        let standings = sampleStandings(lastRaceAt: lastDate)
        let resolved = MenuBarLabelFormatter.resolveMode(
            .auto,
            prefs: MenuBarPreferences(),
            nextSession: nil,
            races: [],
            standings: standings,
            now: .now
        )
        #expect(resolved == .lastRace)
    }

    @Test("auto skips last race when spoiler-free")
    func autoSpoiler() {
        let lastDate = Date().addingTimeInterval(-2 * 3600)
        let standings = sampleStandings(lastRaceAt: lastDate)
        let resolved = MenuBarLabelFormatter.resolveMode(
            .auto,
            prefs: MenuBarPreferences(favoriteDriverCode: "ANT", spoilerFree: true),
            nextSession: nil,
            races: [],
            standings: standings,
            now: .now
        )
        #expect(resolved == .myDriver)
    }
}

private func sampleStandings(lastRaceAt: Date? = nil) -> StandingsSnapshot {
    let last: LastRaceResults? = lastRaceAt.map { date in
        LastRaceResults(
            season: "2026",
            round: 5,
            raceName: "Sample Grand Prix",
            dateUTC: date,
            results: [
                RaceResultEntry(
                    position: 1, points: 25, driverId: "antonelli", code: "ANT", givenName: "Andrea Kimi",
                    familyName: "Antonelli", constructorId: "mercedes")
            ]
        )
    }
    return StandingsSnapshot(
        season: "2026",
        round: 5,
        drivers: [
            DriverStanding(
                position: 1, points: 292, wins: 8, driverId: "antonelli", code: "ANT", givenName: "Andrea Kimi",
                familyName: "Antonelli", constructorId: "mercedes", constructorName: "Mercedes"),
            DriverStanding(
                position: 2, points: 250, wins: 3, driverId: "other", code: "OTH", givenName: "Other",
                familyName: "Driver", constructorId: "other", constructorName: "Other"),
        ],
        constructors: [
            ConstructorStanding(position: 1, points: 503, wins: 10, constructorId: "mercedes", name: "Mercedes")
        ],
        lastRace: last
    )
}

private func makeWeekend(raceAt: Date) -> RaceWeekend {
    RaceWeekend(
        season: "2026",
        round: 1,
        name: "Test Grand Prix",
        circuitName: "Test",
        locality: "Test",
        country: "Test",
        sessions: [Session(kind: .race, dateUTC: raceAt)]
    )
}

private func fixture(_ name: String) throws -> Data {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}
