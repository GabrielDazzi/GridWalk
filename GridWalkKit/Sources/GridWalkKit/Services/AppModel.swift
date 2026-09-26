import Foundation
import Observation

/// App-wide state and wiring. Views read it and call its intents; they never touch services directly.
///
/// The schedule and standings stores stay the source of truth for feed data. This model owns the user's
/// preferences and the side effects that follow from them (alerts, widget, Live Activity, Calendar).
@Observable
@MainActor
public final class AppModel {
    public let schedule: ScheduleStore
    public let standings: StandingsStore

    public var preferences: UserPreferences {
        didSet {
            guard preferences != oldValue else { return }
            preferencesStorage.save(preferences)
            pendingWork = Task { await syncSideEffects() }
        }
    }

    public private(set) var calendarResult: CalendarResult?

    /// How often the background loop checks feeds, the widget and the Live Activity.
    public static let tickInterval: Duration = .seconds(60)

    private let preferencesStorage: any PreferencesStoring
    private let notifications: any NotificationScheduling
    private let liveActivity: any LiveActivityControlling
    private let widgets: any WidgetPublishing
    private let calendar: any CalendarExporting
    private let time: any TimeSource
    private var startTask: Task<Void, Never>?
    private var lastPublishedSnapshot: WidgetSnapshot?
    private var lastScheduledAlerts: [SessionAlert]?
    // lets tests wait for side effects kicked off by a preference change
    private(set) var pendingWork: Task<Void, Never>?

    public init(
        schedule: ScheduleStore,
        standings: StandingsStore,
        preferencesStorage: any PreferencesStoring,
        notifications: any NotificationScheduling,
        liveActivity: any LiveActivityControlling,
        widgets: any WidgetPublishing,
        calendar: any CalendarExporting,
        time: any TimeSource = SystemTimeSource()
    ) {
        self.schedule = schedule
        self.standings = standings
        self.preferencesStorage = preferencesStorage
        self.preferences = preferencesStorage.load()
        self.notifications = notifications
        self.liveActivity = liveActivity
        self.widgets = widgets
        self.calendar = calendar
        self.time = time
    }

    /// Real services: Jolpica, the App Group cache, UserNotifications, ActivityKit, WidgetKit, EventKit.
    public static func live() -> AppModel {
        #if os(iOS)
        let liveActivity: any LiveActivityControlling = SessionLiveActivityController()
        #else
        let liveActivity: any LiveActivityControlling = NoLiveActivity()
        #endif
        return AppModel(
            schedule: .live(),
            standings: .live(),
            preferencesStorage: DefaultsPreferencesStorage(),
            notifications: UserNotificationScheduler(),
            liveActivity: liveActivity,
            widgets: SharedWidgetPublisher(),
            calendar: WeekendCalendarExporter()
        )
    }

    // MARK: - Lifecycle

    /// Loads caches and refreshes what's stale. Safe to call from several views; the work runs once.
    public func start() async {
        if let startTask {
            await startTask.value
            return
        }
        let task = Task { await performStart() }
        startTask = task
        await task.value
    }

    /// Starts, then keeps feeds, alerts, widget and Live Activity current until the calling task is cancelled.
    public func run() async {
        await start()
        while !Task.isCancelled {
            try? await Task.sleep(for: Self.tickInterval)
            guard !Task.isCancelled else { return }
            await tick()
        }
    }

    /// One pass of the background loop.
    public func tick() async {
        await schedule.refreshIfNeeded()
        await standings.refreshIfNeeded(races: schedule.races)
        await syncSideEffects()
    }

    /// User pulled to refresh or tapped Refresh.
    public func refreshNow() async {
        await schedule.refreshNow()
        await standings.refresh()
        await syncSideEffects()
    }

    /// One-tap reveal: marks the hidden weekend as watched.
    public func revealResults(at now: Date) {
        guard let weekend = spoilerState(at: now).hiddenWeekend else { return }
        preferences.spoilers.watchedWeekendIDs = SpoilerPolicy.watchedIDs(
            afterMarking: weekend,
            in: preferences.spoilers,
            races: schedule.races
        )
    }

    public func requestNotificationPermission() async -> Bool {
        await notifications.requestAuthorization()
    }

    public func addToCalendar(_ weekend: RaceWeekend) async {
        do throws(CalendarExportError) {
            let count = try await calendar.addWeekend(weekend)
            calendarResult = .added(count: count)
        } catch {
            calendarResult = .failed(error)
        }
    }

    // MARK: - Derived state

    public func nextSession(at now: Date) -> TimedSession? {
        schedule.nextSession(at: now)
    }

    public func currentWeekend(at now: Date) -> RaceWeekend? {
        schedule.currentWeekend(at: now)
    }

    public func spoilerState(at now: Date) -> SpoilerState {
        SpoilerPolicy.state(races: schedule.races, preferences: preferences.spoilers, now: now)
    }

    /// Favorite driver, or favorite team when no driver is picked.
    public var favoriteSummary: FavoriteSummary? {
        guard let snapshot = standings.snapshot else { return nil }
        if let driver = snapshot.drivers.first(where: preferences.favorites.isFavorite) {
            return FavoriteSummary(driver)
        }
        return snapshot.constructors.first(where: preferences.favorites.isFavorite).map(FavoriteSummary.init)
    }

    public func favoriteSnippet(at now: Date) -> FavoriteSnippet {
        FavoriteSnippet.make(
            snapshot: standings.snapshot,
            favorites: preferences.favorites,
            spoilers: spoilerState(at: now)
        )
    }

    public func hero(at now: Date) -> HeroState {
        WeekendTimeline.hero(races: schedule.races, at: now)
    }

    public func menuBarContext(at now: Date) -> MenuBarContext {
        MenuBarContext(
            nextSession: nextSession(at: now),
            races: schedule.races,
            standings: standings.snapshot,
            favorites: preferences.favorites,
            resultsHidden: spoilerState(at: now).isHidingResults,
            now: now
        )
    }

    public func menuBarLabel(at now: Date, tick: Int) -> MenuBarLabelContent {
        let mode = MenuBarLabelFormatter.activeMode(
            preferences: preferences.menuBar,
            tick: tick,
            resultsHidden: spoilerState(at: now).isHidingResults
        )
        return MenuBarLabelFormatter.content(mode: mode, context: menuBarContext(at: now))
    }

    /// VoiceOver text for the menu bar item: the countdown spelled out, or the full label of other modes.
    public func menuBarAccessibilityLabel(at now: Date, tick: Int) -> String {
        let mode = MenuBarLabelFormatter.activeMode(
            preferences: preferences.menuBar,
            tick: tick,
            resultsHidden: spoilerState(at: now).isHidingResults
        )
        let context = menuBarContext(at: now)
        if MenuBarLabelFormatter.resolveMode(mode, context: context) == .countdown, let next = context.nextSession {
            return CountdownFormat.accessibilityLabel(for: next.session.kind, until: next.session.dateUTC, from: now)
        }
        return MenuBarLabelFormatter.content(mode: mode, context: context).text
    }

    // MARK: - Side effects

    private func performStart() async {
        await schedule.bootstrap()
        await standings.bootstrap(races: schedule.races)
        await syncSideEffects()
    }

    private func syncSideEffects() async {
        let now = time.now
        let next = nextSession(at: now)

        let alerts = SessionAlertPlanner.alerts(races: schedule.races, preferences: preferences.alerts, now: now)
        if alerts != lastScheduledAlerts {
            lastScheduledAlerts = alerts
            await notifications.replaceAlerts(with: alerts)
        }

        let spoilers = spoilerState(at: now)
        let snapshot = next.map {
            WidgetSnapshot(
                timed: $0,
                lastUpdated: schedule.lastUpdated ?? now,
                favorite: favoriteSummary,
                spoilers: spoilers
            )
        }
        if snapshot != lastPublishedSnapshot {
            lastPublishedSnapshot = snapshot
            await widgets.publish(snapshot)
        }

        await liveActivity.sync(with: next, now: now)
    }
}

/// Outcome of the last "add to Calendar" tap.
public enum CalendarResult: Sendable, Equatable {
    case added(count: Int)
    case failed(CalendarExportError)
}
