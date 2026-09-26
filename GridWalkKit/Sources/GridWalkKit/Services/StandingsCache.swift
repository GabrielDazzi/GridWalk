import Foundation

public struct StandingsCache: Sendable {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(fileManager: FileManager = .default) throws {
        let folder = try AppGroup.cacheDirectory(fileManager: fileManager)
        self.fileURL = folder.appendingPathComponent("standings.json")
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public init(directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent("standings.json")
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func load() throws -> StandingsSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try decoder.decode(StandingsSnapshot.self, from: Data(contentsOf: fileURL))
    }

    public func save(_ snapshot: StandingsSnapshot) throws {
        try encoder.encode(snapshot).write(to: fileURL, options: .atomic)
    }
}
