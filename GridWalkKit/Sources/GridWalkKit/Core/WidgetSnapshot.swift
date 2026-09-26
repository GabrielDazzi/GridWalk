import Foundation

/// The favorite's current standing, as shown on the widget.
public struct FavoriteSummary: Codable, Sendable, Hashable {
    /// Driver code or team name.
    public let name: String
    public let position: Int
    public let points: String

    public init(name: String, position: Int, points: String) {
        self.name = name
        self.position = position
        self.points = points
    }

    public init(_ driver: DriverStanding) {
        self.init(name: driver.displayCode, position: driver.position, points: driver.pointsString)
    }

    public init(_ team: ConstructorStanding) {
        self.init(name: team.name, position: team.position, points: team.pointsString)
    }
}

/// Compact next-session payload for WidgetKit timelines. The app writes it; the widget only reads it.
public struct WidgetSnapshot: Codable, Sendable, Hashable {
    public let sessionKindRaw: String
    public let sessionShortName: String
    public let sessionDisplayName: String
    public let dateUTC: Date
    public let weekendName: String
    public let isSprintWeekend: Bool
    public let lastUpdated: Date
    /// Favorite driver (or team when no driver is picked). Nil while there's nothing to show.
    public let favorite: FavoriteSummary?
    /// Spoiler-free: hide `favorite` until this date. Nil when nothing is hidden.
    public let resultsHiddenUntil: Date?

    public var sessionKind: SessionKind? {
        SessionKind(rawValue: sessionKindRaw)
    }

    public init(
        sessionKindRaw: String,
        sessionShortName: String,
        sessionDisplayName: String,
        dateUTC: Date,
        weekendName: String,
        isSprintWeekend: Bool,
        lastUpdated: Date,
        favorite: FavoriteSummary? = nil,
        resultsHiddenUntil: Date? = nil
    ) {
        self.sessionKindRaw = sessionKindRaw
        self.sessionShortName = sessionShortName
        self.sessionDisplayName = sessionDisplayName
        self.dateUTC = dateUTC
        self.weekendName = weekendName
        self.isSprintWeekend = isSprintWeekend
        self.lastUpdated = lastUpdated
        self.favorite = favorite
        self.resultsHiddenUntil = resultsHiddenUntil
    }

    public init(
        timed: TimedSession,
        lastUpdated: Date,
        favorite: FavoriteSummary? = nil,
        spoilers: SpoilerState = .visible
    ) {
        self.init(
            sessionKindRaw: timed.session.kind.rawValue,
            sessionShortName: timed.session.kind.shortName,
            sessionDisplayName: timed.session.kind.displayName,
            dateUTC: timed.session.dateUTC,
            weekendName: timed.weekend.name,
            isSprintWeekend: timed.weekend.isSprintWeekend,
            lastUpdated: lastUpdated,
            favorite: favorite,
            resultsHiddenUntil: spoilers.isHidingResults ? spoilers.revealDate : nil
        )
    }

    /// The favorite line to show at `date`, or nil while spoiler-free hides it.
    public func visibleFavorite(at date: Date) -> FavoriteSummary? {
        if let resultsHiddenUntil, date < resultsHiddenUntil { return nil }
        return favorite
    }

    public func isHidingResults(at date: Date) -> Bool {
        guard let resultsHiddenUntil, favorite != nil else { return false }
        return date < resultsHiddenUntil
    }

    /// Moments the widget should redraw: the reveal, then the session start.
    public func timelineDates(after now: Date) -> [Date] {
        [resultsHiddenUntil, dateUTC].compactMap { $0 }.filter { $0 > now }.sorted()
    }
}

public enum WidgetSnapshotStore {
    public static let fileName = "widget_snapshot.json"

    public static func save(_ snapshot: WidgetSnapshot?, in directory: URL) throws {
        let url = directory.appendingPathComponent(fileName)
        let fm = FileManager.default
        guard let snapshot else {
            try? fm.removeItem(at: url)
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }

    public static func save(_ snapshot: WidgetSnapshot?, fileManager: FileManager = .default) throws {
        let folder = try AppGroup.cacheDirectory(fileManager: fileManager)
        try save(snapshot, in: folder)
    }

    public static func load(from directory: URL) -> WidgetSnapshot? {
        let url = directory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path),
            let data = try? Data(contentsOf: url)
        else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    public static func load(fileManager: FileManager = .default) -> WidgetSnapshot? {
        guard let folder = try? AppGroup.cacheDirectory(fileManager: fileManager) else { return nil }
        return load(from: folder)
    }
}
