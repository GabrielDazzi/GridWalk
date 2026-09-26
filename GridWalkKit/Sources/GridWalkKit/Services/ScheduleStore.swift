import Foundation
import Observation

/// Source of truth for the season schedule.
///
/// Loads the cache first, then refreshes from the feed at most every 12 hours. A failed refresh keeps
/// whatever was cached and records `lastError` so the UI can show "last updated".
@Observable
@MainActor
public final class ScheduleStore {
    public private(set) var schedule: SeasonSchedule?
    public private(set) var isRefreshing = false
    public private(set) var lastError: FeedError?

    public static let refreshInterval: TimeInterval = 12 * 60 * 60
    /// Manual refreshes closer together than this are ignored.
    public static let manualRefreshCooldown: TimeInterval = 60
    /// After a failed refresh, automatic retries wait this long.
    public static let retryInterval: TimeInterval = 15 * 60

    private let feed: any FeedFetching
    private let cache: any Caching<SeasonSchedule>
    private let time: any TimeSource
    private var lastAttempt: Date?

    public init(feed: any FeedFetching, cache: any Caching<SeasonSchedule>, time: any TimeSource = SystemTimeSource()) {
        self.feed = feed
        self.cache = cache
        self.time = time
    }

    /// Live store backed by Jolpica and the shared cache file.
    public static func live() -> ScheduleStore {
        let cache: any Caching<SeasonSchedule> =
            (try? FileCache<SeasonSchedule>.shared(fileName: "season.json")) ?? MemoryCache()
        return ScheduleStore(feed: JolpicaClient(), cache: cache)
    }

    public var races: [RaceWeekend] { schedule?.races ?? [] }
    public var lastUpdated: Date? { schedule?.fetchedAt }

    /// Loads the cache (if nothing is loaded yet), then refreshes when stale.
    public func bootstrap() async {
        if schedule == nil {
            schedule = try? await cache.load()
        }
        await refreshIfNeeded()
    }

    public func refreshIfNeeded() async {
        let now = time.now
        if let lastUpdated, now.timeIntervalSince(lastUpdated) < Self.refreshInterval {
            return
        }
        if lastError != nil, let lastAttempt, now.timeIntervalSince(lastAttempt) < Self.retryInterval {
            return
        }
        await refresh()
    }

    /// Manual refresh from the UI. Still rate limited so repeated taps don't hammer the feed.
    public func refreshNow() async {
        if let lastAttempt, time.now.timeIntervalSince(lastAttempt) < Self.manualRefreshCooldown {
            return
        }
        await refresh()
    }

    private func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        lastAttempt = time.now
        defer { isRefreshing = false }

        do throws(FeedError) {
            let data = try await feed.data(for: .schedule)
            let fresh = try SeasonDecoder.decode(data, fetchedAt: time.now)
            try? await cache.save(fresh)
            schedule = fresh
            lastError = nil
        } catch {
            lastError = error
            if schedule == nil {
                schedule = try? await cache.load()
            }
        }
    }

    public func nextSession(at now: Date) -> TimedSession? {
        guard let pair = schedule?.nextSession(after: now) else { return nil }
        return TimedSession(weekend: pair.weekend, session: pair.session)
    }

    public func currentWeekend(at now: Date) -> RaceWeekend? {
        schedule?.currentWeekend(at: now)
    }
}
