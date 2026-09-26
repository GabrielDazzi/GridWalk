import Foundation
import Testing

@testable import GridWalkKit

@Suite("Schedule store")
@MainActor
struct ScheduleStoreTests {
    @Test("loads the feed and caches it")
    func loadsAndCaches() async throws {
        let cache = MemoryCache<SeasonSchedule>()
        let time = ManualTimeSource(try utcDate("2026-03-01T00:00:00Z"))
        let store = ScheduleStore(feed: FixtureFeed(), cache: cache, time: time)

        await store.bootstrap()

        #expect(store.races.count == 23)
        #expect(store.lastError == nil)
        #expect(store.lastUpdated == time.now)
        #expect(await cache.load()?.races.count == 23)
    }

    @Test("fresh cache means no network call")
    func freshCacheSkipsNetwork() async throws {
        let now = try utcDate("2026-03-01T00:00:00Z")
        let cached = try SeasonDecoder.decode(try fixture("current_season"), fetchedAt: now.addingTimeInterval(-3600))
        let counter = RequestCounter()
        let store = ScheduleStore(
            feed: CountingFeed(base: FixtureFeed(), counter: counter),
            cache: MemoryCache(cached),
            time: ManualTimeSource(now)
        )

        await store.bootstrap()

        #expect(await counter.count == 0)
        #expect(store.races.count == 23)
    }

    @Test("refreshes after 12 hours, not before")
    func twelveHourRule() async throws {
        let time = ManualTimeSource(try utcDate("2026-03-01T00:00:00Z"))
        let counter = RequestCounter()
        let store = ScheduleStore(
            feed: CountingFeed(base: FixtureFeed(), counter: counter),
            cache: MemoryCache(),
            time: time
        )

        await store.bootstrap()
        #expect(await counter.count == 1)

        time.advance(by: 11 * 3600)
        await store.refreshIfNeeded()
        #expect(await counter.count == 1)

        time.advance(by: 2 * 3600)
        await store.refreshIfNeeded()
        #expect(await counter.count == 2)
    }

    @Test("manual refresh has a cooldown")
    func manualCooldown() async throws {
        let time = ManualTimeSource(try utcDate("2026-03-01T00:00:00Z"))
        let counter = RequestCounter()
        let store = ScheduleStore(
            feed: CountingFeed(base: FixtureFeed(), counter: counter),
            cache: MemoryCache(),
            time: time
        )

        await store.refreshNow()
        await store.refreshNow()
        #expect(await counter.count == 1)

        time.advance(by: ScheduleStore.manualRefreshCooldown + 1)
        await store.refreshNow()
        #expect(await counter.count == 2)
    }

    @Test("feed failure keeps the cache and reports the error")
    func failureFallsBack() async throws {
        let now = try utcDate("2026-03-01T00:00:00Z")
        let stale = try SeasonDecoder.decode(try fixture("current_season"), fetchedAt: now.addingTimeInterval(-86_400))
        let store = ScheduleStore(
            feed: FixtureFeed(failure: .offline),
            cache: MemoryCache(stale),
            time: ManualTimeSource(now)
        )

        await store.bootstrap()

        #expect(store.lastError == .offline)
        #expect(store.races.count == 23)
        #expect(store.lastUpdated == stale.fetchedAt)
    }

    @Test("next session moves with the clock passed in")
    func nextSessionUsesNow() async throws {
        let store = ScheduleStore(feed: FixtureFeed(), cache: MemoryCache(), time: SystemTimeSource())
        await store.refreshNow()
        let early = try #require(store.nextSession(at: try utcDate("2026-01-01T00:00:00Z")))
        #expect(early.weekend.round == 1)
        #expect(early.session.kind == .practice1)
        #expect(store.nextSession(at: try utcDate("2027-01-01T00:00:00Z")) == nil)
    }
}

@Suite("Standings store")
@MainActor
struct StandingsStoreTests {
    @Test("fetches the three documents after a race")
    func fetchesAfterRace() async throws {
        let raceDate = try utcDate("2026-05-10T13:00:00Z")
        let time = ManualTimeSource(raceDate.addingTimeInterval(StandingsMath.postRaceGrace + 60))
        let counter = RequestCounter()
        let store = StandingsStore(
            feed: CountingFeed(base: FixtureFeed(), counter: counter),
            cache: MemoryCache(sampleStandings(fetchedAt: raceDate.addingTimeInterval(-86_400))),
            time: time
        )

        await store.bootstrap(races: [makeWeekend(raceAt: raceDate)])

        #expect(await counter.count == 3)
        #expect(store.snapshot?.round == 14)
    }

    @Test("does not refetch before the post-race grace window")
    func waitsForGrace() async throws {
        let raceDate = try utcDate("2026-05-10T13:00:00Z")
        let counter = RequestCounter()
        let store = StandingsStore(
            feed: CountingFeed(base: FixtureFeed(), counter: counter),
            cache: MemoryCache(sampleStandings(fetchedAt: raceDate.addingTimeInterval(-86_400))),
            time: ManualTimeSource(raceDate.addingTimeInterval(3600))
        )

        await store.bootstrap(races: [makeWeekend(raceAt: raceDate)])

        #expect(await counter.count == 0)
        #expect(store.snapshot?.round == 5)
    }

    @Test("feed failure keeps cached standings")
    func failureKeepsCache() async throws {
        let store = StandingsStore(
            feed: FixtureFeed(failure: .timedOut),
            cache: MemoryCache(sampleStandings()),
            time: SystemTimeSource()
        )
        await store.refresh()
        #expect(store.lastError == .timedOut)
        #expect(store.snapshot?.drivers.count == 2)
    }
}

@Suite("File cache")
struct FileCacheTests {
    @Test("round-trips through disk and reports corrupt files")
    func roundTrip() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("standings.json")
        let cache = FileCache<StandingsSnapshot>(fileURL: url)

        #expect(try await cache.load() == nil)
        let snapshot = sampleStandings(fetchedAt: Date(timeIntervalSince1970: 1_000_000))
        try await cache.save(snapshot)
        #expect(try await cache.load() == snapshot)

        try Data("garbage".utf8).write(to: url)
        await #expect(throws: CacheError.unreadable) {
            try await cache.load()
        }
    }
}
