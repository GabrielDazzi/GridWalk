import Foundation
import Testing

@testable import GridWalkKit

@Suite("Weekend timeline")
struct WeekendTimelineTests {
    // sprint weekend: FP1 + SQ Friday, Sprint + Q Saturday, Race Sunday (UTC)
    static func sprintWeekend() throws -> RaceWeekend {
        makeWeekend(
            round: 6,
            name: "Sprint Grand Prix",
            sessions: [
                Session(kind: .practice1, dateUTC: try utcDate("2026-05-01T16:30:00Z")),
                Session(kind: .sprintQualifying, dateUTC: try utcDate("2026-05-01T20:30:00Z")),
                Session(kind: .sprint, dateUTC: try utcDate("2026-05-02T16:00:00Z")),
                Session(kind: .qualifying, dateUTC: try utcDate("2026-05-02T20:00:00Z")),
                Session(kind: .race, dateUTC: try utcDate("2026-05-03T20:00:00Z")),
            ]
        )
    }

    let utc = TimeZone.gmt
    let english = Locale(identifier: "en_US")

    @Test("phases: finished, live, next, later")
    func phases() throws {
        let weekend = try Self.sprintWeekend()
        let now = try utcDate("2026-05-02T16:20:00Z")  // 20 min into the sprint
        let phases = weekend.sessions.map { WeekendTimeline.phase(of: $0, in: weekend, at: now) }
        #expect(phases == [.finished, .finished, .live, .next, .later])
    }

    @Test("a session is live for its typical length, then finished")
    func liveWindow() throws {
        let weekend = try Self.sprintWeekend()
        let race = try #require(weekend.sessions.last)
        #expect(WeekendTimeline.phase(of: race, in: weekend, at: race.dateUTC) == .live)
        let after = race.dateUTC.addingTimeInterval(SessionKind.race.typicalDuration)
        #expect(WeekendTimeline.phase(of: race, in: weekend, at: after) == .finished)
    }

    @Test("groups sessions by local day in UTC")
    func groupsByDayUTC() throws {
        let days = WeekendTimeline.days(
            for: try Self.sprintWeekend(),
            at: try utcDate("2026-04-30T00:00:00Z"),
            timeZone: utc,
            locale: english
        )
        #expect(days.map(\.rows.count) == [2, 2, 1])
        #expect(days.first?.title == "Friday, May 1")
    }

    @Test("a late session moves to the next day for users east of the track")
    func groupsByDayInTokyo() throws {
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let days = WeekendTimeline.days(
            for: try Self.sprintWeekend(),
            at: try utcDate("2026-04-30T00:00:00Z"),
            timeZone: tokyo,
            locale: english
        )
        // 16:30 UTC Friday is 01:30 Saturday in Tokyo, so the whole weekend shifts a day
        #expect(days.map(\.rows.count) == [2, 2, 1])
        #expect(days.first?.title == "Saturday, May 2")
        #expect(days.last?.title == "Monday, May 4")
    }

    @Test("rows carry a spoken label with the phase")
    func accessibilityLabels() throws {
        let weekend = try Self.sprintWeekend()
        let days = WeekendTimeline.days(
            for: weekend,
            at: try utcDate("2026-05-02T16:20:00Z"),
            timeZone: utc,
            locale: english
        )
        let rows = days.flatMap(\.rows)
        #expect(rows[0].accessibilityLabel.hasSuffix("finished"))
        #expect(rows[2].accessibilityLabel.contains("live now"))
        #expect(rows[3].accessibilityLabel.hasSuffix("up next"))
    }

    @Test("hero: upcoming, then live, then off-season after the finale")
    func hero() throws {
        let weekend = try Self.sprintWeekend()
        let race = try #require(weekend.sessions.last)

        let before = WeekendTimeline.hero(races: [weekend], at: try utcDate("2026-05-01T00:00:00Z"))
        #expect(before == .upcoming(TimedSession(weekend: weekend, session: weekend.sessions[0])))

        let during = WeekendTimeline.hero(races: [weekend], at: race.dateUTC.addingTimeInterval(600))
        #expect(during == .live(TimedSession(weekend: weekend, session: race)))

        let after = WeekendTimeline.hero(races: [weekend], at: race.dateUTC.addingTimeInterval(3 * 3600))
        #expect(after == .offSeason(lastWeekend: weekend))
        #expect(after.weekend == nil)
    }

    @Test("empty schedule is off-season with no last weekend")
    func emptySchedule() {
        #expect(WeekendTimeline.hero(races: [], at: .now) == .offSeason(lastWeekend: nil))
    }
}
