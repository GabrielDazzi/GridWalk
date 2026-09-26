import Foundation
import Testing

@testable import GridWalkKit

@Suite("Spoiler policy")
struct SpoilerPolicyTests {
    // sprint weekend: sprint Saturday 16:00Z, race Sunday 14:00Z
    private func sprintWeekend(round: Int = 6) throws -> RaceWeekend {
        makeWeekend(
            round: round,
            name: "Sprint Grand Prix",
            sessions: [
                Session(kind: .practice1, dateUTC: try utcDate("2026-05-01T16:00:00Z")),
                Session(kind: .sprintQualifying, dateUTC: try utcDate("2026-05-01T20:00:00Z")),
                Session(kind: .sprint, dateUTC: try utcDate("2026-05-02T16:00:00Z")),
                Session(kind: .qualifying, dateUTC: try utcDate("2026-05-02T20:00:00Z")),
                Session(kind: .race, dateUTC: try utcDate("2026-05-03T14:00:00Z")),
            ]
        )
    }

    private let enabled = SpoilerPreferences(isEnabled: true, revealDelay: .twoDays)

    @Test("off means nothing is hidden")
    func disabled() throws {
        let races = [try sprintWeekend()]
        let state = SpoilerPolicy.state(
            races: races,
            preferences: SpoilerPreferences(isEnabled: false),
            now: try utcDate("2026-05-03T16:00:00Z")
        )
        #expect(state == .visible)
    }

    @Test("practice and qualifying alone don't hide anything")
    func beforeScoring() throws {
        let state = SpoilerPolicy.state(
            races: [try sprintWeekend()],
            preferences: enabled,
            now: try utcDate("2026-05-02T10:00:00Z")
        )
        #expect(!state.isHidingResults)
    }

    @Test("sprint start hides results until 48h after the race")
    func sprintHides() throws {
        let weekend = try sprintWeekend()
        let state = SpoilerPolicy.state(
            races: [weekend],
            preferences: enabled,
            now: try utcDate("2026-05-02T16:00:00Z")
        )
        #expect(state.hiddenWeekend == weekend)
        #expect(state.revealDate == (try utcDate("2026-05-05T14:00:00Z")))
    }

    @Test("reveal delay passing shows results again")
    func delayPasses() throws {
        let races = [try sprintWeekend()]
        let justBefore = SpoilerPolicy.state(
            races: races,
            preferences: enabled,
            now: try utcDate("2026-05-05T13:59:00Z")
        )
        let after = SpoilerPolicy.state(races: races, preferences: enabled, now: try utcDate("2026-05-05T14:00:00Z"))
        #expect(justBefore.isHidingResults)
        #expect(!after.isHidingResults)
    }

    @Test("delay is configurable", arguments: RevealDelay.allCases)
    func configurable(delay: RevealDelay) throws {
        let race = try utcDate("2026-05-03T14:00:00Z")
        let preferences = SpoilerPreferences(isEnabled: true, revealDelay: delay)
        let races = [try sprintWeekend()]
        let inside = SpoilerPolicy.state(
            races: races, preferences: preferences, now: race.addingTimeInterval(delay.interval - 1))
        let outside = SpoilerPolicy.state(
            races: races, preferences: preferences, now: race.addingTimeInterval(delay.interval))
        #expect(inside.isHidingResults)
        #expect(!outside.isHidingResults)
    }

    @Test("marking the weekend watched reveals it")
    func watched() throws {
        let weekend = try sprintWeekend()
        var preferences = enabled
        preferences.watchedWeekendIDs = SpoilerPolicy.watchedIDs(
            afterMarking: weekend, in: preferences, races: [weekend])
        let state = SpoilerPolicy.state(
            races: [weekend], preferences: preferences, now: try utcDate("2026-05-03T18:00:00Z"))
        #expect(!state.isHidingResults)
    }

    @Test("only the latest scored weekend counts")
    func latestOnly() throws {
        let earlier = makeWeekend(round: 5, raceAt: try utcDate("2026-04-26T14:00:00Z"))
        let latest = try sprintWeekend()
        let state = SpoilerPolicy.state(
            races: [earlier, latest],
            preferences: enabled,
            now: try utcDate("2026-05-02T17:00:00Z")
        )
        #expect(state.hiddenWeekend == latest)
    }

    @Test("watched ids drop weekends that left the schedule")
    func pruning() throws {
        let weekend = try sprintWeekend()
        let preferences = SpoilerPreferences(isEnabled: true, watchedWeekendIDs: ["2025-22", weekend.id])
        let ids = SpoilerPolicy.watchedIDs(afterMarking: weekend, in: preferences, races: [weekend])
        #expect(ids == [weekend.id])
    }

    @Test("off-season after the finale reveals once the delay passes")
    func offSeason() throws {
        let finale = makeWeekend(round: 24, raceAt: try utcDate("2026-12-06T13:00:00Z"))
        let during = SpoilerPolicy.state(
            races: [finale], preferences: enabled, now: try utcDate("2026-12-07T13:00:00Z"))
        let later = SpoilerPolicy.state(races: [finale], preferences: enabled, now: try utcDate("2027-01-15T00:00:00Z"))
        #expect(during.isHidingResults)
        #expect(!later.isHidingResults)
    }
}

@Suite("Widget spoilers")
struct WidgetSpoilerTests {
    private func snapshot(hiddenUntil: Date?) throws -> WidgetSnapshot {
        WidgetSnapshot(
            sessionKindRaw: SessionKind.race.rawValue,
            sessionShortName: "Race",
            sessionDisplayName: "Race",
            dateUTC: try utcDate("2026-05-10T14:00:00Z"),
            weekendName: "Next Grand Prix",
            isSprintWeekend: false,
            lastUpdated: .now,
            favorite: FavoriteSummary(name: "ANT", position: 1, points: "292"),
            resultsHiddenUntil: hiddenUntil
        )
    }

    @Test("favorite is hidden until the reveal date")
    func hidesFavorite() throws {
        let reveal = try utcDate("2026-05-05T14:00:00Z")
        let widget = try snapshot(hiddenUntil: reveal)
        #expect(widget.visibleFavorite(at: reveal.addingTimeInterval(-1)) == nil)
        #expect(widget.isHidingResults(at: reveal.addingTimeInterval(-1)))
        #expect(widget.visibleFavorite(at: reveal)?.name == "ANT")
        #expect(!widget.isHidingResults(at: reveal))
    }

    @Test("timeline redraws at the reveal and at the session")
    func timeline() throws {
        let reveal = try utcDate("2026-05-05T14:00:00Z")
        let widget = try snapshot(hiddenUntil: reveal)
        let dates = widget.timelineDates(after: try utcDate("2026-05-04T00:00:00Z"))
        #expect(dates == [reveal, widget.dateUTC])
        #expect(widget.timelineDates(after: reveal) == [widget.dateUTC])
    }

    @Test("snapshots from before spoiler support still decode")
    func legacyDecode() throws {
        let json = Data(
            #"""
            {"sessionKindRaw":"race","sessionShortName":"Race","sessionDisplayName":"Race",
             "dateUTC":"2026-05-10T14:00:00Z","weekendName":"X","isSprintWeekend":false,
             "lastUpdated":"2026-05-01T00:00:00Z"}
            """#.utf8
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(WidgetSnapshot.self, from: json)
        #expect(decoded.favorite == nil)
        #expect(decoded.resultsHiddenUntil == nil)
    }
}

@Suite("App model spoilers")
@MainActor
struct AppModelSpoilerTests {
    @Test("widget gets the hide date, reveal clears it")
    func revealFlow() async throws {
        // Chinese GP (sprint weekend) sprint is 2026-03-14 03:00Z in the fixture season
        let now = try utcDate("2026-03-14T05:00:00Z")
        var preferences = UserPreferences()
        preferences.spoilers = SpoilerPreferences(isEnabled: true)
        preferences.favorites = Favorites(driverCode: "ANT")
        let harness = AppModelHarness(now: now, preferences: preferences)
        await harness.model.start()

        let state = harness.model.spoilerState(at: now)
        #expect(state.hiddenWeekend?.name == "Chinese Grand Prix")
        let hidden = try #require(await harness.widgets.published.last ?? nil)
        #expect(hidden.resultsHiddenUntil == state.revealDate)
        #expect(hidden.visibleFavorite(at: now) == nil)
        #expect(harness.model.menuBarLabel(at: now, tick: 0).systemImage == "timer")

        harness.model.revealResults(at: now)
        await harness.model.pendingWork?.value

        #expect(!harness.model.spoilerState(at: now).isHidingResults)
        #expect(harness.storage.stored.spoilers.watchedWeekendIDs.contains(try #require(state.hiddenWeekend?.id)))
        let revealed = try #require(await harness.widgets.published.last ?? nil)
        #expect(revealed.resultsHiddenUntil == nil)
        #expect(revealed.visibleFavorite(at: now)?.name == "ANT")
    }
}
