import Foundation
import Testing

@testable import GridWalkKit

@Suite("Season decoding")
struct SeasonDecodingTests {
    @Test("parses a regular weekend without sprint")
    func regularWeekend() throws {
        let data = try fixture("regular_weekend")
        let season = try SeasonDecoder.decode(data)

        #expect(season.races.count == 1)
        let race = try #require(season.races.first)
        #expect(!race.isSprintWeekend)

        let kinds = race.sessions.map(\.kind)
        #expect(kinds.contains(.practice1))
        #expect(kinds.contains(.practice2))
        #expect(kinds.contains(.practice3))
        #expect(kinds.contains(.qualifying))
        #expect(kinds.contains(.race))
        #expect(!kinds.contains(.sprint))
        #expect(!kinds.contains(.sprintQualifying))
    }

    @Test("parses a sprint weekend")
    func sprintWeekend() throws {
        let data = try fixture("sprint_weekend")
        let season = try SeasonDecoder.decode(data)
        let race = try #require(season.races.first)

        #expect(race.isSprintWeekend)
        let kinds = Set(race.sessions.map(\.kind))
        #expect(kinds.contains(.sprint))
        #expect(kinds.contains(.sprintQualifying))
        #expect(kinds.contains(.qualifying))
        #expect(kinds.contains(.race))
        #expect(!kinds.contains(.practice2))
        #expect(!kinds.contains(.practice3))
    }

    @Test("parses full current season fixture")
    func fullSeason() throws {
        let data = try fixture("current_season")
        let season = try SeasonDecoder.decode(data)
        #expect(season.races.count >= 20)
        #expect(!season.season.isEmpty)
    }
}

@Suite("UTC to local")
struct TimeConversionTests {
    @Test("UTC instant maps to expected local components")
    func utcToSaoPaulo() throws {
        // 2026-03-08 04:00:00Z → 01:00 in America/Sao_Paulo (UTC-3)
        let date = try #require(SeasonDecoder.parseUTC(date: "2026-03-08", time: "04:00:00Z"))
        let zone = try #require(TimeZone(identifier: "America/Sao_Paulo"))
        let comps = LocalTimeFormat.components(of: date, in: zone)

        #expect(comps.year == 2026)
        #expect(comps.month == 3)
        #expect(comps.day == 8)
        #expect(comps.hour == 1)
        #expect(comps.minute == 0)
    }

    @Test("missing time defaults to midnight UTC")
    func missingTime() throws {
        let date = try #require(SeasonDecoder.parseUTC(date: "2026-03-08", time: nil))
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let comps = LocalTimeFormat.components(of: date, in: zone)
        #expect(comps.hour == 0)
        #expect(comps.minute == 0)
    }
}

@Suite("Next session")
struct NextSessionTests {
    @Test("picks the earliest upcoming session")
    func picksNext() throws {
        let data = try fixture("regular_weekend")
        let season = try SeasonDecoder.decode(data)
        let race = try #require(season.races.first)
        let fp1 = try #require(race.sessions.first { $0.kind == .practice1 })

        let before = fp1.dateUTC.addingTimeInterval(-3600)
        let next = try #require(season.nextSession(after: before)?.session)
        #expect(next.kind == .practice1)

        let afterFP1 = fp1.dateUTC.addingTimeInterval(60)
        let next2 = try #require(season.nextSession(after: afterFP1)?.session)
        #expect(next2.kind == .practice2)
    }

    @Test("returns nil when the season is over")
    func seasonOver() throws {
        let data = try fixture("regular_weekend")
        let season = try SeasonDecoder.decode(data)
        let last = try #require(season.races.first?.sessions.last)
        let after = last.dateUTC.addingTimeInterval(3600)
        #expect(season.nextSession(after: after) == nil)
    }
}

@Suite("Widget snapshot")
struct WidgetSnapshotTests {
    @Test("builds snapshot from season schedule")
    func fromSeason() throws {
        let data = try fixture("regular_weekend")
        let season = try SeasonDecoder.decode(data)
        let race = try #require(season.races.first)
        let fp1 = try #require(race.sessions.first { $0.kind == .practice1 })
        let before = fp1.dateUTC.addingTimeInterval(-3600)

        let snapshot = try #require(WidgetSnapshot.from(schedule: season, now: before))
        #expect(snapshot.sessionKind == .practice1)
        #expect(snapshot.weekendName == race.name)
        #expect(snapshot.dateUTC == fp1.dateUTC)
    }

    @Test("round-trips through disk store")
    func diskRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let data = try fixture("sprint_weekend")
        let season = try SeasonDecoder.decode(data)
        let snapshot = try #require(WidgetSnapshot.from(schedule: season, now: Date.distantPast))
        try WidgetSnapshotStore.save(snapshot, in: dir)

        let loaded = try #require(WidgetSnapshotStore.load(from: dir))
        #expect(loaded.isSprintWeekend)
        #expect(loaded.sessionKind == snapshot.sessionKind)
        #expect(loaded.weekendName == snapshot.weekendName)
    }
}

@Suite("Live activity policy")
struct LiveActivityPolicyTests {
    @Test("shows only inside the lead window")
    func leadWindow() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        #expect(LiveActivityPolicy.shouldShow(sessionStart: now.addingTimeInterval(3600), now: now))
        #expect(!LiveActivityPolicy.shouldShow(sessionStart: now.addingTimeInterval(8 * 3600), now: now))
        #expect(!LiveActivityPolicy.shouldShow(sessionStart: now.addingTimeInterval(-60), now: now))
    }
}
