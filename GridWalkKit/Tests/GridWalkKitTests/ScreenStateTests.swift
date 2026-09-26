import Foundation
import Testing

@testable import GridWalkKit

@Suite("Screen states")
struct ScreenStateTests {
    let now = Date(timeIntervalSince1970: 1_780_000_000)

    @Test("feed status covers loading, ready, stale and failed")
    func feedStatus() {
        #expect(FeedStatus(lastUpdated: nil, error: nil, isRefreshing: true) == .loading)
        #expect(FeedStatus(lastUpdated: nil, error: nil, isRefreshing: false) == .loading)
        #expect(FeedStatus(lastUpdated: now, error: nil, isRefreshing: false) == .ready(lastUpdated: now))
        #expect(
            FeedStatus(lastUpdated: now, error: .offline, isRefreshing: false)
                == .stale(lastUpdated: now, error: .offline)
        )
        #expect(FeedStatus(lastUpdated: nil, error: .offline, isRefreshing: false) == .failed(.offline))
        // a retry in flight shows the spinner instead of the old error
        #expect(FeedStatus(lastUpdated: nil, error: .offline, isRefreshing: true) == .loading)
        #expect(FeedStatus.stale(lastUpdated: now, error: .offline).isOffline)
    }

    @MainActor
    @Test("store status after an offline refresh with a cache")
    func storeStatus() async {
        let cached = SampleData.schedule(around: now)
        let old = SeasonSchedule(season: cached.season, races: cached.races, fetchedAt: now.addingTimeInterval(-86_400))
        let store = ScheduleStore(
            feed: FixtureFeed(failure: .offline),
            cache: MemoryCache(old),
            time: ManualTimeSource(now)
        )
        await store.bootstrap()
        #expect(store.status == .stale(lastUpdated: old.fetchedAt, error: .offline))
    }

    @Test("season rows: finished, current, upcoming")
    func seasonRows() {
        let races = SampleData.schedule(around: now).races
        let rows = SeasonOverview.rows(races, at: now, timeZone: .gmt, locale: Locale(identifier: "en_US"))
        #expect(rows.map(\.status) == [.finished, .finished, .current, .upcoming])
        #expect(SeasonOverview.scrollTarget(in: rows) == races[2].id)
        #expect(rows[2].accessibilityLabel.contains("sprint weekend"))
        #expect(!rows[2].dates.isEmpty)
    }

    @Test("off-season: every weekend finished, nothing current")
    func offSeasonRows() {
        let races = SampleData.schedule(around: now, offSeason: true).races
        let rows = SeasonOverview.rows(races, at: now)
        #expect(rows.allSatisfy { $0.status == .finished })
        #expect(SeasonOverview.scrollTarget(in: rows) == nil)
    }

    @Test("favorite snippet: hidden wins, then rows, then pick, then unavailable")
    func favoriteSnippet() {
        let snapshot = SampleData.standings(fetchedAt: now)
        let weekend = SampleData.schedule(around: now).races[2]
        let hidden = SpoilerState(hiddenWeekend: weekend, revealDate: now)

        #expect(
            FavoriteSnippet.make(snapshot: snapshot, favorites: SampleData.favorites, spoilers: hidden)
                == .hidden(weekend: weekend, revealDate: now)
        )

        guard
            case .rows(let rows) = FavoriteSnippet.make(
                snapshot: snapshot, favorites: SampleData.favorites, spoilers: .visible)
        else {
            Issue.record("expected rows")
            return
        }
        #expect(rows.map(\.title) == ["OKA", "Kestrel"])
        let allFavorites = rows.allSatisfy(\.isFavorite)
        #expect(allFavorites)

        #expect(FavoriteSnippet.make(snapshot: snapshot, favorites: Favorites(), spoilers: .visible) == .pickFavorites)
        #expect(
            FavoriteSnippet.make(snapshot: nil, favorites: SampleData.favorites, spoilers: .visible) == .unavailable)
    }

    @Test("onboarding lists drivers and teams by name, never by position")
    func onboardingChoices() {
        let snapshot = SampleData.standings(fetchedAt: now)
        let drivers = OnboardingChoices.drivers(in: snapshot)
        #expect(
            drivers.map(\.title) == [
                "Tomas Alvarez", "Ines Berg", "Oskar Hansen", "Jae Kim",
                "Claire Moreau", "Lena Novak", "Ren Okafor", "Rafael Silva",
            ]
        )
        #expect(drivers.first?.id == "ALV")
        #expect(OnboardingChoices.teams(in: snapshot).map(\.title) == ["Apex", "Kestrel", "Northline", "Vector"])
        #expect(OnboardingChoices.drivers(in: nil).isEmpty)
    }

    @MainActor
    @Test("preview scenarios land in the state they're named after")
    func previewScenarios() async {
        let now = Date.now
        let ready = AppModel.preview(.raceWeekend, now: now)
        await ready.start()
        #expect(ready.schedule.status == .ready(lastUpdated: now))
        #expect(ready.hero(at: now).weekend?.round == 3)
        #expect(!ready.spoilerState(at: now).isHidingResults)

        let hidden = AppModel.preview(.resultsHidden, now: now)
        await hidden.start()
        #expect(hidden.spoilerState(at: now).isHidingResults)

        let offline = AppModel.preview(.offline, now: now)
        await offline.start()
        #expect(offline.schedule.status.isOffline)
        #expect(offline.standings.status.isOffline)

        let failed = AppModel.preview(.failed, now: now)
        await failed.start()
        #expect(failed.schedule.status == .failed(.offline))

        let offSeason = AppModel.preview(.offSeason, now: now)
        await offSeason.start()
        #expect(offSeason.hero(at: now).weekend == nil)

        #expect(!AppModel.preview(.firstLaunch).preferences.hasFinishedOnboarding)
        #expect(AppModel.preview(.loading).schedule.status == .loading)
    }

    @MainActor
    @Test("menu bar VoiceOver label spells out the countdown")
    func menuBarAccessibilityLabel() async {
        let now = Date.now
        let model = AppModel.preview(.raceWeekend, now: now)
        await model.start()
        let label = model.menuBarAccessibilityLabel(at: now, tick: 0)
        #expect(label.hasPrefix("Qualifying in 1 day"))
    }

    @Test("menu bar step only on the Mac")
    func onboardingSteps() {
        #expect(OnboardingStep.steps(includesMenuBar: true).contains(.menuBar))
        #expect(!OnboardingStep.steps(includesMenuBar: false).contains(.menuBar))
        #expect(OnboardingStep.steps(includesMenuBar: false).first == .welcome)
    }
}
