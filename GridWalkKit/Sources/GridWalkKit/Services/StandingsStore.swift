import Foundation
import Observation

/// Source of truth for driver and team standings plus the last race result.
///
/// Refreshes only once a race has finished (see `StandingsMath.needsRefresh`), never on a timer.
@Observable
@MainActor
public final class StandingsStore {
    public private(set) var snapshot: StandingsSnapshot?
    public private(set) var isRefreshing = false
    public private(set) var lastError: FeedError?

    private let feed: any FeedFetching
    private let cache: any Caching<StandingsSnapshot>
    private let time: any TimeSource
    private var lastAttempt: Date?

    public init(
        feed: any FeedFetching,
        cache: any Caching<StandingsSnapshot>,
        time: any TimeSource = SystemTimeSource()
    ) {
        self.feed = feed
        self.cache = cache
        self.time = time
    }

    /// Live store backed by Jolpica and the shared cache file.
    public static func live() -> StandingsStore {
        let cache: any Caching<StandingsSnapshot> =
            (try? FileCache<StandingsSnapshot>.shared(fileName: "standings.json")) ?? MemoryCache()
        return StandingsStore(feed: JolpicaClient(), cache: cache)
    }

    public func bootstrap(races: [RaceWeekend]) async {
        if snapshot == nil {
            snapshot = try? await cache.load()
        }
        await refreshIfNeeded(races: races)
    }

    public func refreshIfNeeded(races: [RaceWeekend]) async {
        let now = time.now
        guard StandingsMath.needsRefresh(races: races, cached: snapshot, now: now) else { return }
        if lastError != nil, let lastAttempt, now.timeIntervalSince(lastAttempt) < ScheduleStore.retryInterval {
            return
        }
        await refresh()
    }

    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        lastAttempt = time.now
        defer { isRefreshing = false }

        do throws(FeedError) {
            let fresh = try await fetchSnapshot()
            try? await cache.save(fresh)
            snapshot = fresh
            lastError = nil
        } catch {
            lastError = error
            if snapshot == nil {
                snapshot = try? await cache.load()
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
                fetchedAt: time.now
            )
        } catch {
            throw FeedError(error)
        }
    }
}
