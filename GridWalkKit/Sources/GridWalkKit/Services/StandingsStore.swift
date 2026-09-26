import Foundation
import Observation

@Observable
@MainActor
public final class StandingsStore {
    public private(set) var snapshot: StandingsSnapshot?
    public private(set) var isRefreshing = false
    public private(set) var lastError: FeedError?

    /// Hours after a race before we consider standings stale enough to refetch.
    public static let postRaceGrace: TimeInterval = StandingsMath.postRaceGrace

    private let feed: any FeedFetching
    private let cache: StandingsCache
    private let clock: () -> Date

    public init(
        feed: any FeedFetching = JolpicaClient(),
        cache: StandingsCache,
        clock: @escaping @Sendable () -> Date = { .now }
    ) {
        self.feed = feed
        self.cache = cache
        self.clock = clock
    }

    public static func makeDefault() -> StandingsStore {
        if let cache = try? StandingsCache() {
            return StandingsStore(cache: cache)
        }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("GridWalkStandings", isDirectory: true)
        let cache = try! StandingsCache(directory: dir)
        return StandingsStore(cache: cache)
    }

    public func bootstrap(races: [RaceWeekend]) async {
        snapshot = try? cache.load()
        await refreshIfNeeded(races: races)
    }

    public func refreshIfNeeded(races: [RaceWeekend], force: Bool = false) async {
        if force {
            await refresh()
            return
        }
        let now = clock()
        if StandingsMath.needsRefresh(races: races, cached: snapshot, now: now) {
            await refresh()
        }
    }

    public func refresh() async {
        if isRefreshing { return }
        isRefreshing = true
        lastError = nil
        defer { isRefreshing = false }

        do throws(FeedError) {
            let fresh = try await fetchSnapshot()
            try? cache.save(fresh)
            snapshot = fresh
        } catch {
            lastError = error
            if snapshot == nil {
                snapshot = try? cache.load()
            }
        }
    }

    private func fetchSnapshot() async throws(FeedError) -> StandingsSnapshot {
        let feed = feed
        do {
            async let drivers = feed.data(for: .driverStandings)
            async let constructors = feed.data(for: .constructorStandings)
            async let results = feed.data(for: .lastResults)
            return try await StandingsDecoder.snapshot(
                drivers: drivers,
                constructors: constructors,
                lastResults: results,
                fetchedAt: clock()
            )
        } catch {
            throw FeedError(error)
        }
    }
}
