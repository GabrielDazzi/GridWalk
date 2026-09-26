import Foundation
import Testing

@testable import GridWalkKit

actor FakeNotifications: NotificationScheduling {
    private(set) var scheduled: [[SessionAlert]] = []
    private(set) var authorizationRequests = 0

    func requestAuthorization() async -> Bool {
        authorizationRequests += 1
        return true
    }

    func replaceAlerts(with alerts: [SessionAlert]) async {
        scheduled.append(alerts)
    }
}

actor FakeWidgets: WidgetPublishing {
    private(set) var published: [WidgetSnapshot?] = []

    func publish(_ snapshot: WidgetSnapshot?) async {
        published.append(snapshot)
    }
}

@MainActor
final class FakeLiveActivity: LiveActivityControlling {
    private(set) var synced: [TimedSession?] = []

    func sync(with next: TimedSession?, now: Date) async {
        synced.append(next)
    }
}

@MainActor
final class FakeCalendar: CalendarExporting {
    var failure: CalendarExportError?

    func addWeekend(_ weekend: RaceWeekend) async throws(CalendarExportError) -> Int {
        if let failure { throw failure }
        return weekend.sessions.count
    }
}

@MainActor
final class MemoryPreferencesStorage: PreferencesStoring {
    var stored: UserPreferences
    private(set) var saveCount = 0

    init(_ preferences: UserPreferences = UserPreferences()) {
        stored = preferences
    }

    func load() -> UserPreferences { stored }

    func save(_ preferences: UserPreferences) {
        stored = preferences
        saveCount += 1
    }
}

@MainActor
struct AppModelHarness {
    let model: AppModel
    let notifications = FakeNotifications()
    let widgets = FakeWidgets()
    let liveActivity = FakeLiveActivity()
    let calendar = FakeCalendar()
    let storage: MemoryPreferencesStorage
    let time: ManualTimeSource

    init(now: Date, preferences: UserPreferences = UserPreferences(), feed: FixtureFeed = FixtureFeed()) {
        time = ManualTimeSource(now)
        storage = MemoryPreferencesStorage(preferences)
        model = AppModel(
            schedule: ScheduleStore(feed: feed, cache: MemoryCache(), time: time),
            standings: StandingsStore(feed: feed, cache: MemoryCache(), time: time),
            preferencesStorage: storage,
            notifications: notifications,
            liveActivity: liveActivity,
            widgets: widgets,
            calendar: calendar,
            time: time
        )
    }
}

@Suite("App model")
@MainActor
struct AppModelTests {
    @Test("start loads both feeds and syncs alerts, widget and Live Activity")
    func start() async throws {
        let harness = AppModelHarness(now: try utcDate("2026-03-01T00:00:00Z"))
        await harness.model.start()

        #expect(harness.model.schedule.races.count == 23)
        #expect(harness.model.standings.snapshot != nil)
        #expect(await harness.notifications.scheduled.count == 1)
        #expect(await harness.widgets.published.last??.weekendName == "Australian Grand Prix")
        #expect(harness.liveActivity.synced.count == 1)
    }

    @Test("start runs once even when several views ask")
    func startOnce() async throws {
        let counter = RequestCounter()
        let now = try utcDate("2026-03-01T00:00:00Z")
        let time = ManualTimeSource(now)
        let feed = CountingFeed(base: FixtureFeed(), counter: counter)
        let model = AppModel(
            schedule: ScheduleStore(feed: feed, cache: MemoryCache(), time: time),
            standings: StandingsStore(feed: feed, cache: MemoryCache(), time: time),
            preferencesStorage: MemoryPreferencesStorage(),
            notifications: FakeNotifications(),
            liveActivity: FakeLiveActivity(),
            widgets: FakeWidgets(),
            calendar: FakeCalendar(),
            time: time
        )
        async let first: Void = model.start()
        async let second: Void = model.start()
        _ = await (first, second)
        #expect(await counter.count == 4)
    }

    @Test("changing preferences saves them and reschedules alerts")
    func preferenceChange() async throws {
        let harness = AppModelHarness(now: try utcDate("2026-03-01T00:00:00Z"))
        await harness.model.start()

        harness.model.preferences.alerts.set(.practice, enabled: true)
        await harness.model.pendingWork?.value

        #expect(harness.storage.stored.alerts.enabled.contains(.practice))
        let scheduled = await harness.notifications.scheduled
        #expect(scheduled.count == 2)
        #expect(scheduled.last?.first?.title == "Practice 1")
    }

    @Test("same preferences don't save or reschedule")
    func noOpChange() async throws {
        let harness = AppModelHarness(now: try utcDate("2026-03-01T00:00:00Z"))
        await harness.model.start()
        harness.model.preferences = harness.model.preferences
        #expect(harness.storage.saveCount == 0)
    }

    @Test("tick publishes a new widget snapshot once the session starts")
    func tickMovesOn() async throws {
        let harness = AppModelHarness(now: try utcDate("2026-03-06T01:00:00Z"))
        await harness.model.start()
        #expect(await harness.widgets.published.last??.sessionKind == .practice1)

        harness.time.advance(by: 3600)
        await harness.model.tick()
        #expect(await harness.widgets.published.last??.sessionKind == .practice2)

        await harness.model.tick()
        #expect(await harness.widgets.published.count == 2)
    }

    @Test("calendar result is reported")
    func calendar() async throws {
        let harness = AppModelHarness(now: try utcDate("2026-03-01T00:00:00Z"))
        await harness.model.start()
        let weekend = try #require(harness.model.currentWeekend(at: harness.time.now))

        await harness.model.addToCalendar(weekend)
        #expect(harness.model.calendarResult == .added(count: 5))

        harness.calendar.failure = .accessDenied
        await harness.model.addToCalendar(weekend)
        #expect(harness.model.calendarResult == .failed(.accessDenied))
    }
}

@Suite("Session alerts")
struct SessionAlertPlannerTests {
    @Test("only enabled, future sessions, soonest first, capped")
    func planning() throws {
        let season = try SeasonDecoder.decode(try fixture("current_season"))
        let now = try utcDate("2026-03-06T01:20:00Z")
        let alerts = SessionAlertPlanner.alerts(
            races: season.races,
            preferences: AlertPreferences(enabled: Set(AlertCategory.allCases)),
            now: now
        )
        #expect(alerts.count == SessionAlertPlanner.maximumPending)
        #expect(alerts.map(\.fireDate) == alerts.map(\.fireDate).sorted())
        // FP1 fires at 01:15, already gone
        #expect(alerts.first?.title == "Practice 2")
        #expect(alerts.allSatisfy { $0.fireDate > now })
    }

    @Test("alerts carry no results")
    func noResults() throws {
        let season = try SeasonDecoder.decode(try fixture("current_season"))
        let alerts = SessionAlertPlanner.alerts(
            races: season.races,
            preferences: AlertPreferences(),
            now: try utcDate("2026-01-01T00:00:00Z")
        )
        #expect(alerts.allSatisfy { $0.body.hasSuffix("starts in 15 minutes") })
    }
}

@Suite("User preferences")
struct UserPreferencesTests {
    @Test("older saved blobs still load with defaults for new fields")
    func partialDecode() throws {
        let json = Data(#"{"favorites":{"driverCode":"ANT"}}"#.utf8)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: json)
        #expect(decoded.favorites.driverCode == "ANT")
        #expect(decoded.alerts == AlertPreferences())
        #expect(!decoded.hasFinishedOnboarding)
    }

    @Test("favorites match by code or driver id")
    func favorites() {
        let favorites = Favorites(driverCode: "ant", constructorId: "mercedes")
        let drivers = sampleStandings().drivers
        #expect(favorites.isFavorite(drivers[0]))
        #expect(!favorites.isFavorite(drivers[1]))
        #expect(Favorites(driverCode: "antonelli").isFavorite(drivers[0]))
        #expect(favorites.isFavorite(sampleStandings().constructors[0]))
    }
}
