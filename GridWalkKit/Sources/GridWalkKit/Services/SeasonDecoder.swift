import Foundation

/// Turns the Jolpica season document into domain models.
///
/// Races that fail to decode are skipped instead of failing the whole season.
public enum SeasonDecoder {
    public static func decode(_ data: Data, fetchedAt: Date = .now) throws(FeedError) -> SeasonSchedule {
        let payload: APIRoot
        do {
            payload = try JSONDecoder().decode(APIRoot.self, from: data)
        } catch {
            throw .malformedData
        }
        let table = payload.mrData.raceTable
        let races = table.races.elements.map(mapRace)
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

    /// Combines "YYYY-MM-DD" and an optional "HH:MM:SSZ" into a UTC date. Returns nil for anything out of range.
    public static func parseUTC(date: String, time: String?) -> Date? {
        let timePart = time.map { $0.hasSuffix("Z") ? String($0.dropLast()) : $0 } ?? "00:00:00"

        let dateParts = date.split(separator: "-").compactMap { Int($0) }
        let timeParts = timePart.split(separator: ":").compactMap { Int($0) }
        guard dateParts.count == 3, (2...3).contains(timeParts.count) else { return nil }

        var components = DateComponents()
        components.year = dateParts[0]
        components.month = dateParts[1]
        components.day = dateParts[2]
        components.hour = timeParts[0]
        components.minute = timeParts[1]
        components.second = timeParts.count > 2 ? timeParts[2] : 0

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        guard components.isValidDate(in: calendar) else { return nil }
        return calendar.date(from: components)
    }
}

/// Decodes an array but drops elements that don't parse.
struct LossyList<Element: Decodable>: Decodable {
    let elements: [Element]

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [Element] = []
        while !container.isAtEnd {
            if let element = try? container.decode(Element.self) {
                elements.append(element)
            } else {
                // skip the broken element so the container moves on
                _ = try? container.decode(Discarded.self)
            }
        }
        self.elements = elements
    }

    // accepts any JSON value, so the index always advances
    private struct Discarded: Decodable {
        init(from decoder: any Decoder) {}
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
    let races: LossyList<APIRace>

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
