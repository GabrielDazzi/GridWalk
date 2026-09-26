import Foundation
import Observation

@Observable
@MainActor
public final class ScheduleStore {
    public private(set) var nextSession: TimedSession?
    public private(set) var currentWeekend: RaceWeekend?
    public private(set) var allRaces: [RaceWeekend] = []
    public private(set) var lastUpdated: Date?
    public private(set) var isRefreshing = false
    public private(set) var lastError: FeedError?

    public static let refreshInterval: TimeInterval = 12 * 60 * 60

    private let feed: any FeedFetching
    private let cache: any SeasonCaching
    private let clock: () -> Date

    public init(
        feed: any FeedFetching = JolpicaClient(),
        cache: any SeasonCaching,
        clock: @escaping @Sendable () -> Date = { .now }
    ) {
        self.feed = feed
        self.cache = cache
        self.clock = clock
    }

    /// Uses Application Support; falls back to memory if that fails.
    public static func makeDefault(feed: any FeedFetching = JolpicaClient()) -> ScheduleStore {
        let cache: any SeasonCaching
        do {
            cache = try SeasonCache()
        } catch {
            cache = MemorySeasonCache()
        }
        return ScheduleStore(feed: feed, cache: cache)
    }

    /// Load cache immediately, then refresh if stale (at most one network call).
    public func bootstrap() async {
        apply(try? cache.load())
        await refreshIfNeeded()
    }

    public func refreshIfNeeded(force: Bool = false) async {
        let now = clock()
        if !force, let lastUpdated, now.timeIntervalSince(lastUpdated) < Self.refreshInterval {
            return
        }
        await refresh(force: force)
    }

    public func refresh(force: Bool = true) async {
        _ = force
        if isRefreshing { return }
        isRefreshing = true
        lastError = nil
        defer { isRefreshing = false }

        do throws(FeedError) {
            let data = try await feed.data(for: .schedule)
            let schedule = try SeasonDecoder.decode(data, fetchedAt: clock())
            try? cache.save(schedule)
            apply(schedule)
            WidgetReload.reloadAll()
        } catch {
            lastError = error
            if allRaces.isEmpty {
                apply(try? cache.load())
            }
        }
    }

    private func apply(_ schedule: SeasonSchedule?) {
        guard let schedule else { return }
        allRaces = schedule.races
        lastUpdated = schedule.fetchedAt
        let now = clock()
        if let pair = schedule.nextSession(after: now) {
            nextSession = TimedSession(weekend: pair.weekend, session: pair.session)
            currentWeekend = pair.weekend
        } else {
            nextSession = nil
            currentWeekend = schedule.currentWeekend(at: now)
            try? WidgetSnapshotStore.save(nil)
        }
    }
}

final class MemorySeasonCache: SeasonCaching, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: SeasonSchedule?

    func load() throws -> SeasonSchedule? {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func save(_ schedule: SeasonSchedule) throws {
        lock.lock()
        defer { lock.unlock() }
        stored = schedule
    }
}
