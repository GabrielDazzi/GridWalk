import Foundation

/// Jolpica / Ergast season JSON → domain models.
public enum SeasonDecoder {
    private static let utc: TimeZone = TimeZone(secondsFromGMT: 0)!

    public static func decode(_ data: Data, fetchedAt: Date = .now) throws -> SeasonSchedule {
        let payload = try JSONDecoder().decode(APIRoot.self, from: data)
        let table = payload.mrData.raceTable
        let races = table.races.map(mapRace)
        return SeasonSchedule(season: table.season, races: races, fetchedAt: fetchedAt)
    }

    private static func mapRace(_ race: APIRace) -> RaceWeekend {
        var sessions: [Session] = []

        append(&sessions, kind: .practice1, from: race.firstPractice)
        append(&sessions, kind: .practice2, from: race.secondPractice)
        append(&sessions, kind: .practice3, from: race.thirdPractice)
        append(&sessions, kind: .sprintQualifying, from: race.sprintQualifying)
        append(&sessions, kind: .sprint, from: race.sprint)
        append(&sessions, kind: .qualifying, from: race.qualifying)

        if let date = parseUTC(date: race.date, time: race.time) {
            sessions.append(Session(kind: .race, dateUTC: date))
        }

        let circuit = race.circuit
        return RaceWeekend(
            season: race.season,
            round: Int(race.round) ?? 0,
            name: race.raceName,
            circuitName: circuit.circuitName,
            locality: circuit.location.locality,
            country: circuit.location.country,
            sessions: sessions
        )
    }

    private static func append(_ sessions: inout [Session], kind: SessionKind, from timing: APITiming?) {
        guard let timing, let date = parseUTC(date: timing.date, time: timing.time) else { return }
        sessions.append(Session(kind: kind, dateUTC: date))
    }

    /// Combines "YYYY-MM-DD" + optional "HH:MM:SSZ" into a UTC Date.
    public static func parseUTC(date: String, time: String?) -> Date? {
        let timePart =
            time.map { t in
                t.hasSuffix("Z") ? String(t.dropLast()) : t
            } ?? "00:00:00"

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc

        let dateBits = date.split(separator: "-").compactMap { Int($0) }
        let timeBits = timePart.split(separator: ":").compactMap { Int($0) }
        guard dateBits.count == 3, timeBits.count >= 2 else { return nil }

        var components = DateComponents()
        components.year = dateBits[0]
        components.month = dateBits[1]
        components.day = dateBits[2]
        components.hour = timeBits[0]
        components.minute = timeBits[1]
        components.second = timeBits.count > 2 ? timeBits[2] : 0
        components.timeZone = utc
        return calendar.date(from: components)
    }
}

// MARK: - API DTOs

private struct APIRoot: Decodable {
    let mrData: APIMRData

    enum CodingKeys: String, CodingKey {
        case mrData = "MRData"
    }
}

private struct APIMRData: Decodable {
    let raceTable: APIRaceTable

    enum CodingKeys: String, CodingKey {
        case raceTable = "RaceTable"
    }
}

private struct APIRaceTable: Decodable {
    let season: String
    let races: [APIRace]

    enum CodingKeys: String, CodingKey {
        case season
        case races = "Races"
    }
}

private struct APIRace: Decodable {
    let season: String
    let round: String
    let raceName: String
    let date: String
    let time: String?
    let circuit: APICircuit
    let firstPractice: APITiming?
    let secondPractice: APITiming?
    let thirdPractice: APITiming?
    let qualifying: APITiming?
    let sprint: APITiming?
    let sprintQualifying: APITiming?

    enum CodingKeys: String, CodingKey {
        case season, round, raceName, date, time
        case circuit = "Circuit"
        case firstPractice = "FirstPractice"
        case secondPractice = "SecondPractice"
        case thirdPractice = "ThirdPractice"
        case qualifying = "Qualifying"
        case sprint = "Sprint"
        case sprintQualifying = "SprintQualifying"
    }
}

private struct APICircuit: Decodable {
    let circuitName: String
    let location: APILocation

    enum CodingKeys: String, CodingKey {
        case circuitName
        case location = "Location"
    }
}

private struct APILocation: Decodable {
    let locality: String
    let country: String
}

private struct APITiming: Decodable {
    let date: String
    let time: String?
}
