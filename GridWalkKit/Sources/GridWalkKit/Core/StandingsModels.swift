import Foundation

public struct DriverStanding: Codable, Sendable, Hashable, Identifiable {
    public var id: String { driverId }
    public let position: Int
    public let points: Double
    public let wins: Int
    public let driverId: String
    public let code: String
    public let givenName: String
    public let familyName: String
    public let constructorId: String
    public let constructorName: String

    public var displayCode: String {
        code.isEmpty ? String(familyName.prefix(3)).uppercased() : code
    }

    public var shortLabel: String {
        "\(displayCode) P\(position) · \(pointsString)"
    }

    public var pointsString: String {
        points.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(points))
            : String(format: "%.1f", points)
    }
}

public struct ConstructorStanding: Codable, Sendable, Hashable, Identifiable {
    public var id: String { constructorId }
    public let position: Int
    public let points: Double
    public let wins: Int
    public let constructorId: String
    public let name: String

    public var shortLabel: String {
        "\(name) P\(position) · \(pointsString)"
    }

    public var pointsString: String {
        points.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(points))
            : String(format: "%.1f", points)
    }
}

public struct RaceResultEntry: Codable, Sendable, Hashable, Identifiable {
    public var id: String { driverId }
    public let position: Int
    public let points: Double
    public let driverId: String
    public let code: String
    public let givenName: String
    public let familyName: String
    public let constructorId: String

    public var displayCode: String {
        code.isEmpty ? String(familyName.prefix(3)).uppercased() : code
    }
}

public struct LastRaceResults: Codable, Sendable, Hashable {
    public let season: String
    public let round: Int
    public let raceName: String
    public let dateUTC: Date
    public let results: [RaceResultEntry]

    public var winner: RaceResultEntry? {
        results.first { $0.position == 1 }
    }

    public func result(forDriverCode code: String) -> RaceResultEntry? {
        let upper = code.uppercased()
        return results.first { $0.displayCode.uppercased() == upper || $0.driverId == code }
    }
}

public struct StandingsSnapshot: Codable, Sendable, Hashable {
    public let season: String
    public let round: Int
    public let drivers: [DriverStanding]
    public let constructors: [ConstructorStanding]
    public let lastRace: LastRaceResults?
    public let fetchedAt: Date

    public init(
        season: String,
        round: Int,
        drivers: [DriverStanding],
        constructors: [ConstructorStanding],
        lastRace: LastRaceResults?,
        fetchedAt: Date = .now
    ) {
        self.season = season
        self.round = round
        self.drivers = drivers
        self.constructors = constructors
        self.lastRace = lastRace
        self.fetchedAt = fetchedAt
    }
}
