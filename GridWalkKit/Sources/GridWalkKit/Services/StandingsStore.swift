import Foundation
import Observation

@Observable
@MainActor
public final class StandingsStore {
    public private(set) var snapshot: StandingsSnapshot?
    public private(set) var isRefreshing = false
    public private(set) var lastError: String?

    /// Hours after a race before we consider standings stale enough to refetch.
    public static let postRaceGrace: TimeInterval = StandingsMath.postRaceGrace

    private let client: StandingsClient
    private let cache: StandingsCache
    private let clock: () -> Date

    public init(
        client: StandingsClient = StandingsClient(),
        cache: StandingsCache,
        clock: @escaping @Sendable () -> Date = { .now }
    ) {
        self.client = client
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

        do {
            let snap = try await client.fetchSnapshot(now: clock())
            try? cache.save(snap)
            snapshot = snap
        } catch {
            lastError = error.localizedDescription
            if snapshot == nil {
                snapshot = try? cache.load()
            }
        }
    }
}
