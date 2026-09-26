import Foundation
import Testing

@testable import GridWalkKit

@Suite("Feed parsing edge cases")
struct FeedParsingTests {
    @Test("garbage JSON is a malformed-data error, not a crash")
    func garbage() {
        #expect(throws: FeedError.malformedData) {
            try SeasonDecoder.decode(Data("{\"nope\": true}".utf8))
        }
        #expect(throws: FeedError.malformedData) {
            try StandingsDecoder.decodeDrivers(Data("[1, 2".utf8))
        }
    }

    @Test("broken races are skipped, good ones kept")
    func partlyBroken() throws {
        let season = try SeasonDecoder.decode(try fixture("partly_broken_season"))
        #expect(season.races.map(\.round) == [1, 3])

        // FP1 had an impossible time, so only quali and race survive
        let first = try #require(season.races.first)
        #expect(first.sessions.map(\.kind) == [.qualifying, .race])
    }

    @Test("pre-season standings decode to empty tables")
    func preseason() throws {
        let snapshot = try StandingsDecoder.snapshot(
            drivers: try fixture("preseason_standings"),
            constructors: try fixture("preseason_standings"),
            lastResults: try fixture("preseason_results"),
            fetchedAt: .now
        )
        #expect(snapshot.drivers.isEmpty)
        #expect(snapshot.constructors.isEmpty)
        #expect(snapshot.lastRace == nil)
        #expect(snapshot.season == "2027")
        #expect(snapshot.round == 0)
    }

    @Test("full snapshot joins the three documents")
    func fullSnapshot() throws {
        let fetchedAt = Date(timeIntervalSince1970: 1_000)
        let snapshot = try StandingsDecoder.snapshot(
            drivers: try fixture("driver_standings"),
            constructors: try fixture("constructor_standings"),
            lastResults: try fixture("last_results"),
            fetchedAt: fetchedAt
        )
        #expect(snapshot.round == 14)
        #expect(snapshot.drivers.first?.displayCode == "ANT")
        #expect(snapshot.lastRace?.results.isEmpty == false)
        #expect(snapshot.fetchedAt == fetchedAt)
    }

    @Test(
        "rejects dates that don't exist",
        arguments: [
            ("2026-02-30", "10:00:00Z"),
            ("2026-13-01", "10:00:00Z"),
            ("2026-03-08", "24:00:00Z"),
            ("2026-03-08", "10"),
            ("08/03/2026", "10:00:00Z"),
        ]
    )
    func invalidDates(date: String, time: String) {
        #expect(SeasonDecoder.parseUTC(date: date, time: time) == nil)
    }

    @Test("accepts times without seconds or Z")
    func shortTime() throws {
        let date = try #require(SeasonDecoder.parseUTC(date: "2026-03-08", time: "04:30"))
        #expect(date == (try utcDate("2026-03-08T04:30:00Z")))
    }
}

@Suite("Feed errors")
struct FeedErrorTests {
    @Test(
        "maps URL errors to something we can explain",
        arguments: [
            (URLError.Code.notConnectedToInternet, FeedError.offline),
            (.networkConnectionLost, .offline),
            (.timedOut, .timedOut),
            (.cannotParseResponse, .malformedData),
            (.badServerResponse, .transport),
        ]
    )
    func urlErrors(code: URLError.Code, expected: FeedError) {
        #expect(FeedError(URLError(code)) == expected)
    }

    @Test("keeps feed errors and maps decoding errors")
    func passthrough() {
        #expect(FeedError(FeedError.server(status: 503)) == .server(status: 503))
        let decoding = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))
        #expect(FeedError(decoding) == .malformedData)
    }

    @Test("every case has a message")
    func messages() {
        let all: [FeedError] = [.offline, .timedOut, .server(status: 500), .emptyResponse, .malformedData, .transport]
        for error in all {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }
}
