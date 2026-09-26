import Foundation

/// Compact next-session payload for WidgetKit timelines.
public struct WidgetSnapshot: Codable, Sendable, Hashable {
    public let sessionKindRaw: String
    public let sessionShortName: String
    public let sessionDisplayName: String
    public let dateUTC: Date
    public let weekendName: String
    public let isSprintWeekend: Bool
    public let lastUpdated: Date

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
        lastUpdated: Date
    ) {
        self.sessionKindRaw = sessionKindRaw
        self.sessionShortName = sessionShortName
        self.sessionDisplayName = sessionDisplayName
        self.dateUTC = dateUTC
        self.weekendName = weekendName
        self.isSprintWeekend = isSprintWeekend
        self.lastUpdated = lastUpdated
    }

    public init(timed: TimedSession, lastUpdated: Date) {
        self.init(
            sessionKindRaw: timed.session.kind.rawValue,
            sessionShortName: timed.session.kind.shortName,
            sessionDisplayName: timed.session.kind.displayName,
            dateUTC: timed.session.dateUTC,
            weekendName: timed.weekend.name,
            isSprintWeekend: timed.weekend.isSprintWeekend,
            lastUpdated: lastUpdated
        )
    }

    public static func from(schedule: SeasonSchedule, now: Date = .now) -> WidgetSnapshot? {
        guard let pair = schedule.nextSession(after: now) else { return nil }
        return WidgetSnapshot(
            timed: TimedSession(weekend: pair.weekend, session: pair.session),
            lastUpdated: schedule.fetchedAt
        )
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
