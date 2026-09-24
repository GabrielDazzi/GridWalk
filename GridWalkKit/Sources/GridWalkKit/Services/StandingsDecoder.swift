import Foundation

public enum StandingsDecoder {
    public static func decodeDrivers(_ data: Data) throws -> (season: String, round: Int, drivers: [DriverStanding]) {
        let root = try JSONDecoder().decode(APIStandingsRoot.self, from: data)
        let list = try requireFirst(root.mrData.standingsTable?.standingsLists)
        let drivers = (list.driverStandings ?? []).compactMap { item -> DriverStanding? in
            guard let driver = item.driver else { return nil }
            let ctor = item.constructors?.first
            return DriverStanding(
                position: Int(item.position) ?? 0,
                points: Double(item.points) ?? 0,
                wins: Int(item.wins) ?? 0,
                driverId: driver.driverId,
                code: driver.code ?? "",
                givenName: driver.givenName,
                familyName: driver.familyName,
                constructorId: ctor?.constructorId ?? "",
                constructorName: ctor?.name ?? ""
            )
        }
        return (list.season, Int(list.round) ?? 0, drivers)
    }

    public static func decodeConstructors(_ data: Data) throws -> (season: String, round: Int, constructors: [ConstructorStanding]) {
        let root = try JSONDecoder().decode(APIStandingsRoot.self, from: data)
        let list = try requireFirst(root.mrData.standingsTable?.standingsLists)
        let ctors = (list.constructorStandings ?? []).compactMap { item -> ConstructorStanding? in
            guard let ctor = item.constructor else { return nil }
            return ConstructorStanding(
                position: Int(item.position) ?? 0,
                points: Double(item.points) ?? 0,
                wins: Int(item.wins) ?? 0,
                constructorId: ctor.constructorId,
                name: ctor.name
            )
        }
        return (list.season, Int(list.round) ?? 0, ctors)
    }

    public static func decodeLastResults(_ data: Data) throws -> LastRaceResults {
        let root = try JSONDecoder().decode(APIResultsRoot.self, from: data)
        let race = try requireFirst(root.mrData.raceTable.races)
        let date = SeasonDecoder.parseUTC(date: race.date, time: race.time) ?? Date.distantPast
        let results = (race.results ?? []).compactMap { item -> RaceResultEntry? in
            guard let driver = item.driver else { return nil }
            return RaceResultEntry(
                position: Int(item.position) ?? 0,
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

    private static func requireFirst<T>(_ array: [T]?) throws -> T {
        guard let first = array?.first else {
            throw SeasonFetchError.emptyBody
        }
        return first
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
    let standingsLists: [APIStandingsList]
    enum CodingKeys: String, CodingKey { case standingsLists = "StandingsLists" }
}

private struct APIStandingsList: Decodable {
    let season: String
    let round: String
    let driverStandings: [APIDriverStanding]?
    let constructorStandings: [APIConstructorStanding]?
    enum CodingKeys: String, CodingKey {
        case season, round
        case driverStandings = "DriverStandings"
        case constructorStandings = "ConstructorStandings"
    }
}

private struct APIDriverStanding: Decodable {
    let position: String
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
    let position: String
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
    let results: [APIResult]?
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
