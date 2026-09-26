import Foundation

/// App states for SwiftUI previews and the debug `-demo` launch argument.
public enum PreviewScenario: String, CaseIterable, Sendable {
    /// Saturday of a sprint weekend, sprint done, qualifying next. Favorites picked.
    case raceWeekend
    /// Same weekend with spoiler-free on, so the sprint result is hidden.
    case resultsHidden
    /// Cached data, last refresh failed with no connection.
    case offline
    /// Nothing cached and the feed failed.
    case failed
    /// Nothing cached, first refresh still running.
    case loading
    /// Season over.
    case offSeason
    /// Fresh install: data loaded, onboarding not done.
    case firstLaunch
}

/// Made-up season data for previews and screenshots. Names are fictional on purpose.
public enum SampleData {
    public static func schedule(around now: Date, offSeason: Bool = false) -> SeasonSchedule {
        let hour: TimeInterval = 3600
        // offset every weekend so the last race ended days ago
        let shift: TimeInterval = offSeason ? -60 * 24 * hour : 0
        func at(_ hours: Double) -> Date { now.addingTimeInterval(hours * hour + shift) }

        let plan: [(Int, String, String, [(SessionKind, Double)])] = [
            (1, "Desert Night Grand Prix", "Sakhir", [(.practice1, -390), (.qualifying, -367), (.race, -343)]),
            (2, "Harbour Grand Prix", "Melbourne", [(.practice1, -222), (.qualifying, -199), (.race, -175)]),
            (
                3, "Lakeside Grand Prix", "Shanghai",
                [(.practice1, -27), (.sprintQualifying, -23), (.sprint, -4), (.qualifying, 28), (.race, 48)]
            ),
            (4, "Coastal Grand Prix", "Miami", [(.practice1, 314), (.qualifying, 337), (.race, 361)]),
        ]
        let races = plan.map { number, name, locality, sessions in
            RaceWeekend(
                season: "2026",
                round: number,
                name: name,
                circuitName: "\(locality) Circuit",
                locality: locality,
                country: "",
                sessions: sessions.map { Session(kind: $0.0, dateUTC: at($0.1)) }
            )
        }
        return SeasonSchedule(season: "2026", races: races, fetchedAt: now)
    }

    public static func standings(fetchedAt: Date) -> StandingsSnapshot {
        let teams = ["Apex": "apex", "Vector": "vector", "Kestrel": "kestrel", "Northline": "northline"]
        let drivers: [(String, String, String, String, Double)] = [
            ("NOV", "Lena", "Novak", "Apex", 43),
            ("ALV", "Tomas", "Alvarez", "Vector", 38),
            ("KIM", "Jae", "Kim", "Apex", 31),
            ("OKA", "Ren", "Okafor", "Kestrel", 26),
            ("BER", "Ines", "Berg", "Vector", 18),
            ("SIL", "Rafael", "Silva", "Northline", 12),
            ("MOR", "Claire", "Moreau", "Kestrel", 6),
            ("HAN", "Oskar", "Hansen", "Northline", 1),
        ]
        let driverRows = drivers.enumerated().map { index, driver in
            DriverStanding(
                position: index + 1,
                points: driver.4,
                wins: index < 2 ? 1 : 0,
                driverId: driver.2.lowercased(),
                code: driver.0,
                givenName: driver.1,
                familyName: driver.2,
                constructorId: teams[driver.3] ?? "",
                constructorName: driver.3
            )
        }
        let teamRows = ["Apex", "Vector", "Kestrel", "Northline"].enumerated().map { index, name in
            ConstructorStanding(
                position: index + 1,
                points: driverRows.filter { $0.constructorName == name }.map(\.points).reduce(0, +),
                wins: index < 2 ? 1 : 0,
                constructorId: teams[name] ?? "",
                name: name
            )
        }
        return StandingsSnapshot(
            season: "2026",
            round: 2,
            drivers: driverRows,
            constructors: teamRows,
            lastRace: nil,
            fetchedAt: fetchedAt
        )
    }

    public static let favorites = Favorites(driverCode: "OKA", constructorId: "kestrel")
}

extension AppModel {
    /// A model with sample data and no real side effects. Nothing here touches the network.
    public static func preview(_ scenario: PreviewScenario = .raceWeekend, now: Date = .now) -> AppModel {
        let day: TimeInterval = 86_400
        var schedule: SeasonSchedule? = SampleData.schedule(around: now, offSeason: scenario == .offSeason)
        var standings: StandingsSnapshot? = SampleData.standings(fetchedAt: now)
        var feed = PreviewFeed(failure: .offline)
        var preferences = UserPreferences(favorites: SampleData.favorites, hasFinishedOnboarding: true)

        switch scenario {
        case .raceWeekend, .offSeason:
            break
        case .resultsHidden:
            preferences.spoilers.isEnabled = true
        case .offline:
            let old = now.addingTimeInterval(-day)
            schedule = SampleData.schedule(around: now).refetched(at: old)
            standings = SampleData.standings(fetchedAt: old.addingTimeInterval(-7 * day))
        case .failed:
            schedule = nil
            standings = nil
        case .loading:
            schedule = nil
            standings = nil
            feed = PreviewFeed(failure: nil)
        case .firstLaunch:
            preferences = UserPreferences()
        }

        return AppModel(
            schedule: ScheduleStore(feed: feed, cache: MemoryCache(schedule)),
            standings: StandingsStore(feed: feed, cache: MemoryCache(standings)),
            preferencesStorage: PreviewPreferences(preferences),
            notifications: PreviewNotifications(),
            liveActivity: NoLiveActivity(),
            widgets: PreviewWidgets(),
            calendar: PreviewCalendar()
        )
    }
}

@MainActor
private final class PreviewPreferences: PreferencesStoring {
    private var saved: UserPreferences

    init(_ preferences: UserPreferences) {
        saved = preferences
    }

    func load() -> UserPreferences { saved }

    func save(_ preferences: UserPreferences) {
        saved = preferences
    }
}

extension SeasonSchedule {
    fileprivate func refetched(at date: Date) -> SeasonSchedule {
        SeasonSchedule(season: season, races: races, fetchedAt: date)
    }
}

// fails right away with `failure`, or hangs forever when it's nil (the loading state)
private struct PreviewFeed: FeedFetching {
    let failure: FeedError?

    func data(for endpoint: FeedEndpoint) async throws(FeedError) -> Data {
        guard let failure else {
            try? await Task.sleep(for: .seconds(24 * 3600))
            throw .timedOut
        }
        throw failure
    }
}

private struct PreviewNotifications: NotificationScheduling {
    func requestAuthorization() async -> Bool { true }
    func replaceAlerts(with alerts: [SessionAlert]) async {}
}

private struct PreviewWidgets: WidgetPublishing {
    func publish(_ snapshot: WidgetSnapshot?) async {}
}

@MainActor
private final class PreviewCalendar: CalendarExporting {
    func addWeekend(_ weekend: RaceWeekend) async throws(CalendarExportError) -> Int { weekend.sessions.count }
}
