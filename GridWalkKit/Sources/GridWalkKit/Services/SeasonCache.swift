import Foundation

public protocol SeasonCaching: Sendable {
    func load() throws -> SeasonSchedule?
    func save(_ schedule: SeasonSchedule) throws
}

public struct SeasonCache: SeasonCaching {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(fileManager: FileManager = .default) throws {
        let support = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = support.appendingPathComponent("GridWalk", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        self.fileURL = folder.appendingPathComponent("season.json")
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Test helper: write under a known folder.
    public init(directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent("season.json")
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func load() throws -> SeasonSchedule? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(SeasonSchedule.self, from: data)
    }

    public func save(_ schedule: SeasonSchedule) throws {
        let data = try encoder.encode(schedule)
        try data.write(to: fileURL, options: .atomic)
    }
}
