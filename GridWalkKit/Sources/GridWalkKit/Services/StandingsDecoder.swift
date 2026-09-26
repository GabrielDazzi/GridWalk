import Foundation

/// One standings document: which round it reflects and its rows.
struct StandingsPage<Entry: Sendable>: Sendable {
    let season: String
    let round: Int
    let entries: [Entry]
}

/// Turns the Jolpica standings and results documents into a `StandingsSnapshot`.
///
/// Before the first race the feed has no standings lists; that decodes to empty tables, not an error.
public enum StandingsDecoder {
    public static func snapshot(
        drivers driverData: Data,
        constructors constructorData: Data,
        lastResults resultsData: Data,
        fetchedAt: Date
    ) throws(FeedError) -> StandingsSnapshot {
        let drivers = try decodeDrivers(driverData)
        let constructors = try decodeConstructors(constructorData)
        let lastRace = try decodeLastResults(resultsData)
        return StandingsSnapshot(
            season: drivers.season,
            round: max(drivers.round, constructors.round),
            drivers: drivers.entries,
            constructors: constructors.entries,
            lastRace: lastRace,
            fetchedAt: fetchedAt
        )
    }

    static func decodeDrivers(_ data: Data) throws(FeedError) -> StandingsPage<DriverStanding> {
        let root = try decode(APIStandingsRoot.self, from: data)
        let season = root.mrData.standingsTable?.season ?? ""
        guard let list = root.mrData.standingsTable?.standingsLists.first else {
            return StandingsPage(season: season, round: 0, entries: [])
        }
        let items = list.driverStandings?.elements ?? []
        let drivers = items.enumerated().compactMap { index, item -> DriverStanding? in
            guard let driver = item.driver else { return nil }
            let team = item.constructors?.first
            return DriverStanding(
                position: item.position.flatMap { Int($0) } ?? index + 1,
                points: Double(item.points) ?? 0,
                wins: Int(item.wins) ?? 0,
                driverId: driver.driverId,
                code: driver.code ?? "",
                givenName: driver.givenName,
                familyName: driver.familyName,
                constructorId: team?.constructorId ?? "",
                constructorName: team?.name ?? ""
            )
        }
        return StandingsPage(season: list.season, round: Int(list.round) ?? 0, entries: drivers)
    }

    static func decodeConstructors(_ data: Data) throws(FeedError) -> StandingsPage<ConstructorStanding> {
        let root = try decode(APIStandingsRoot.self, from: data)
        let season = root.mrData.standingsTable?.season ?? ""
        guard let list = root.mrData.standingsTable?.standingsLists.first else {
            return StandingsPage(season: season, round: 0, entries: [])
        }
        let items = list.constructorStandings?.elements ?? []
        let constructors = items.enumerated().compactMap { index, item -> ConstructorStanding? in
            guard let team = item.constructor else { return nil }
            return ConstructorStanding(
                position: item.position.flatMap { Int($0) } ?? index + 1,
                points: Double(item.points) ?? 0,
                wins: Int(item.wins) ?? 0,
                constructorId: team.constructorId,
                name: team.name
            )
        }
        return StandingsPage(season: list.season, round: Int(list.round) ?? 0, entries: constructors)
    }

    static func decodeLastResults(_ data: Data) throws(FeedError) -> LastRaceResults? {
        let root = try decode(APIResultsRoot.self, from: data)
        guard let race = root.mrData.raceTable.races.first else { return nil }
        let date = SeasonDecoder.parseUTC(date: race.date, time: race.time) ?? Date.distantPast
        let items = race.results?.elements ?? []
        let results = items.enumerated().compactMap { index, item -> RaceResultEntry? in
            guard let driver = item.driver else { return nil }
            return RaceResultEntry(
                position: Int(item.position) ?? index + 1,
                points: Double(item.points) ?? 0,
                driverId: driver.driverId,
                code: driver.code ?? "",
                givenName: driver.givenName,
                familyName: driver.familyName,
                constructorId: item.constructor?.constructorId ?? ""
            )
        }
        return LastRaceResults(
            season: race.season,
            round: Int(race.round) ?? 0,
            raceName: race.raceName,
            dateUTC: date,
            results: results.sorted { $0.position < $1.position }
        )
    }

    private static func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws(FeedError) -> Value {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw .malformedData
        }
    }
}

// MARK: - DTOs

private struct APIStandingsRoot: Decodable {
    let mrData: APIStandingsMRData
    enum CodingKeys: String, CodingKey { case mrData = "MRData" }
}

private struct APIStandingsMRData: Decodable {
    let standingsTable: APIStandingsTable?
    enum CodingKeys: String, CodingKey { case standingsTable = "StandingsTable" }
}

private struct APIStandingsTable: Decodable {
    let season: String?
    let standingsLists: [APIStandingsList]
    enum CodingKeys: String, CodingKey {
        case season
        case standingsLists = "StandingsLists"
    }
}

private struct APIStandingsList: Decodable {
    let season: String
    let round: String
    let driverStandings: LossyList<APIDriverStanding>?
    let constructorStandings: LossyList<APIConstructorStanding>?
    enum CodingKeys: String, CodingKey {
        case season, round
        case driverStandings = "DriverStandings"
        case constructorStandings = "ConstructorStandings"
    }
}

private struct APIDriverStanding: Decodable {
    let position: String?
    let points: String
    let wins: String
    let driver: APIDriver?
    let constructors: [APIConstructor]?
    enum CodingKeys: String, CodingKey {
        case position, points, wins
        case driver = "Driver"
        case constructors = "Constructors"
    }
}

private struct APIConstructorStanding: Decodable {
    let position: String?
    let points: String
    let wins: String
    let constructor: APIConstructor?
    enum CodingKeys: String, CodingKey {
        case position, points, wins
        case constructor = "Constructor"
    }
}

private struct APIDriver: Decodable {
    let driverId: String
    let code: String?
    let givenName: String
    let familyName: String
}

private struct APIConstructor: Decodable {
    let constructorId: String
    let name: String
}

private struct APIResultsRoot: Decodable {
    let mrData: APIResultsMRData
    enum CodingKeys: String, CodingKey { case mrData = "MRData" }
}

private struct APIResultsMRData: Decodable {
    let raceTable: APIResultsRaceTable
    enum CodingKeys: String, CodingKey { case raceTable = "RaceTable" }
}

private struct APIResultsRaceTable: Decodable {
    let races: [APIResultsRace]
    enum CodingKeys: String, CodingKey { case races = "Races" }
}

private struct APIResultsRace: Decodable {
    let season: String
    let round: String
    let raceName: String
    let date: String
    let time: String?
    let results: LossyList<APIResult>?
    enum CodingKeys: String, CodingKey {
        case season, round, raceName, date, time
        case results = "Results"
    }
}

private struct APIResult: Decodable {
    let position: String
    let points: String
    let driver: APIDriver?
    let constructor: APIConstructor?
    enum CodingKeys: String, CodingKey {
        case position, points
        case driver = "Driver"
        case constructor = "Constructor"
    }
}
