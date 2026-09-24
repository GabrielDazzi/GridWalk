import Foundation

public struct StandingsClient: Sendable {
    public static let driversURL = URL(string: "https://api.jolpi.ca/ergast/f1/current/driverStandings.json")!
    public static let constructorsURL = URL(string: "https://api.jolpi.ca/ergast/f1/current/constructorStandings.json")!
    public static let lastResultsURL = URL(string: "https://api.jolpi.ca/ergast/f1/current/last/results.json")!

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchSnapshot(now: Date = .now) async throws -> StandingsSnapshot {
        async let driversData = fetch(Self.driversURL)
        async let ctorsData = fetch(Self.constructorsURL)
        async let resultsData = fetch(Self.lastResultsURL)

        let (dData, cData, rData) = try await (driversData, ctorsData, resultsData)
        let drivers = try StandingsDecoder.decodeDrivers(dData)
        let ctors = try StandingsDecoder.decodeConstructors(cData)
        let lastRace = try StandingsDecoder.decodeLastResults(rData)

        return StandingsSnapshot(
            season: drivers.season,
            round: max(drivers.round, ctors.round),
            drivers: drivers.drivers,
            constructors: ctors.constructors,
            lastRace: lastRace,
            fetchedAt: now
        )
    }

    private func fetch(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SeasonFetchError.badStatus(http.statusCode)
        }
        guard !data.isEmpty else { throw SeasonFetchError.emptyBody }
        return data
    }
}

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
