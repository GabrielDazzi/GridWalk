import Foundation
import Testing

@testable import GridWalkKit

@Suite("Standings decoding")
struct StandingsDecodingTests {
    @Test("parses driver standings")
    func drivers() throws {
        let data = try fixture("driver_standings")
        let decoded = try StandingsDecoder.decodeDrivers(data)
        #expect(!decoded.entries.isEmpty)
        let leader = try #require(decoded.entries.first)
        #expect(leader.position == 1)
        #expect(!leader.displayCode.isEmpty)
    }

    @Test("parses constructor standings")
    func constructors() throws {
        let data = try fixture("constructor_standings")
        let decoded = try StandingsDecoder.decodeConstructors(data)
        #expect(!decoded.entries.isEmpty)
        #expect(decoded.entries.first?.position == 1)
    }

    @Test("parses last race results")
    func lastResults() throws {
        let data = try fixture("last_results")
        let last = try #require(try StandingsDecoder.decodeLastResults(data))
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
    private let now = Date(timeIntervalSince1970: 1_780_000_000)

    private func context(
        next: TimedSession? = nil,
        races: [RaceWeekend] = [],
        standings: StandingsSnapshot? = sampleStandings(),
        favorites: Favorites = Favorites(),
        resultsHidden: Bool = false
    ) -> MenuBarContext {
        MenuBarContext(
            nextSession: next,
            races: races,
            standings: standings,
            favorites: favorites,
            resultsHidden: resultsHidden,
            now: now
        )
    }

    @Test("formats my driver")
    func myDriver() {
        let content = MenuBarLabelFormatter.format(
            mode: .myDriver,
            context: context(favorites: Favorites(driverCode: "ANT"))
        )
        #expect(content?.text.contains("ANT") == true)
        #expect(content?.text.contains("P1") == true)
    }

    @Test("formats my team and asks for a pick when none is set")
    func myTeam() {
        let picked = MenuBarLabelFormatter.format(
            mode: .myTeam,
            context: context(favorites: Favorites(constructorId: "mercedes"))
        )
        #expect(picked?.compactText == "P1")
        let unpicked = MenuBarLabelFormatter.format(mode: .myTeam, context: context())
        #expect(unpicked?.text == "Pick a team")
    }

    @Test("title fight shows gap")
    func titleFightGap() {
        let races = (0..<6).map { index in
            makeWeekend(round: index, raceAt: now.addingTimeInterval(Double(index + 1) * 14 * 86_400))
        }
        let content = MenuBarLabelFormatter.titleFight(standings: sampleStandings(), races: races, now: now)
        #expect(content.text == "+42")
    }

    @Test("title fight late in the season")
    func titleFightLate() {
        let races = (0..<3).map { index in
            makeWeekend(round: index, raceAt: now.addingTimeInterval(Double(index + 1) * 7 * 86_400))
        }
        let standings = StandingsSnapshot(
            season: "2026",
            round: 20,
            drivers: [
                makeDriver(position: 1, points: 300, code: "AAA"), makeDriver(position: 2, points: 290, code: "BBB"),
            ],
            constructors: [],
            lastRace: nil
        )
        let content = MenuBarLabelFormatter.titleFight(standings: standings, races: races, now: now)
        #expect(content.text.hasPrefix("Still in the fight"))
        #expect(content.compactText == "+10")
    }

    @Test("title fight champion when gap exceeds points left")
    func titleFightChampion() {
        let standings = StandingsSnapshot(
            season: "2026",
            round: 20,
            drivers: [
                makeDriver(position: 1, points: 400, code: "AAA"), makeDriver(position: 2, points: 300, code: "BBB"),
            ],
            constructors: [],
            lastRace: nil
        )
        let races = [makeWeekend(raceAt: now.addingTimeInterval(7 * 86_400))]
        let content = MenuBarLabelFormatter.titleFight(standings: standings, races: races, now: now)
        #expect(content.text == "Champion")
    }

    @Test("hidden results hide the last race")
    func hiddenLastRace() {
        let content = MenuBarLabelFormatter.format(mode: .lastRace, context: context(resultsHidden: true))
        #expect(content == nil)
        let resolved = MenuBarLabelFormatter.resolveMode(.lastRace, context: context(resultsHidden: true))
        #expect(resolved == .countdown)
    }

    @Test("auto picks countdown on race weekend")
    func autoWeekend() {
        let start = now.addingTimeInterval(2 * 3600)
        let timed = TimedSession(
            weekend: makeWeekend(raceAt: start.addingTimeInterval(2 * 86_400)),
            session: Session(kind: .qualifying, dateUTC: start)
        )
        #expect(MenuBarLabelFormatter.resolveMode(.auto, context: context(next: timed)) == .countdown)
    }

    @Test("auto picks last race after race when results are visible")
    func autoPostRace() {
        let standings = sampleStandings(lastRaceAt: now.addingTimeInterval(-2 * 3600))
        #expect(MenuBarLabelFormatter.resolveMode(.auto, context: context(standings: standings)) == .lastRace)
    }

    @Test("auto falls back to the countdown while results are hidden")
    func autoHidden() {
        let standings = sampleStandings(lastRaceAt: now.addingTimeInterval(-2 * 3600))
        let resolved = MenuBarLabelFormatter.resolveMode(
            .auto,
            context: context(standings: standings, favorites: Favorites(driverCode: "ANT"), resultsHidden: true)
        )
        #expect(resolved == .countdown)
    }

    @Test(
        "every standings-based mode is hidden with results",
        arguments: [MenuBarMode.myDriver, .myTeam, .titleFight, .lastRace])
    func standingsModesHidden(mode: MenuBarMode) {
        let hidden = context(
            standings: sampleStandings(lastRaceAt: now.addingTimeInterval(-3600)),
            favorites: Favorites(driverCode: "ANT", constructorId: "mercedes"),
            resultsHidden: true
        )
        #expect(MenuBarLabelFormatter.format(mode: mode, context: hidden) == nil)
        #expect(MenuBarLabelFormatter.resolveMode(mode, context: hidden) == .countdown)
    }

    @Test("ticker rotates and skips result modes while hidden")
    func ticker() {
        var preferences = MenuBarPreferences(mode: .countdown)
        preferences.setTickerModes([.countdown, .lastRace, .titleFight])
        #expect(MenuBarLabelFormatter.activeMode(preferences: preferences, tick: 1, resultsHidden: false) == .lastRace)
        #expect(
            MenuBarLabelFormatter.activeMode(preferences: preferences, tick: 2, resultsHidden: false) == .titleFight)
        #expect(MenuBarLabelFormatter.activeMode(preferences: preferences, tick: 1, resultsHidden: true) == .countdown)
        #expect(MenuBarLabelFormatter.activeMode(preferences: preferences, tick: 2, resultsHidden: true) == .countdown)
    }
}

@Suite("Menu bar preferences")
struct MenuBarPreferencesTests {
    @Test("ticker keeps at most three unique modes and never auto")
    func tickerLimits() {
        var preferences = MenuBarPreferences()
        preferences.setTickerModes([.auto, .countdown, .countdown, .myDriver, .myTeam, .titleFight])
        #expect(preferences.tickerModes == [.countdown, .myDriver, .myTeam])
        #expect(preferences.isTickerActive)

        preferences.setTicker(.lastRace, included: true)
        #expect(preferences.tickerModes.count == 3)

        preferences.setTicker(.myDriver, included: false)
        preferences.setTicker(.myTeam, included: false)
        #expect(!preferences.isTickerActive)
    }
}
