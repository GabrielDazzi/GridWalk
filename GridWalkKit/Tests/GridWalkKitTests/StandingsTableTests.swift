import Foundation
import Testing

@testable import GridWalkKit

@Suite("Standings table")
struct StandingsTableTests {
    private let snapshot = StandingsSnapshot(
        season: "2026",
        round: 10,
        drivers: [
            makeDriver(position: 2, points: 250.5, code: "BBB", team: "blue"),
            makeDriver(position: 1, points: 292, code: "AAA", team: "silver"),
            makeDriver(position: 3, points: 200, code: "CCC", team: "blue"),
        ],
        constructors: [
            ConstructorStanding(position: 1, points: 500, wins: 6, constructorId: "silver", name: "Silver"),
            ConstructorStanding(position: 2, points: 450, wins: 4, constructorId: "blue", name: "Blue"),
        ],
        lastRace: nil
    )

    @Test("drivers sorted by position with gaps to the leader")
    func drivers() {
        let rows = StandingsTable.rows(.drivers, in: snapshot, favorites: Favorites())
        #expect(rows.map(\.title) == ["AAA", "BBB", "CCC"])
        #expect(rows.map(\.gapToLeader) == [nil, "-41.5", "-92"])
        #expect(rows[1].points == "250.5")
    }

    @Test("favorite driver is marked and is the scroll target")
    func favoriteDriver() {
        let rows = StandingsTable.rows(.drivers, in: snapshot, favorites: Favorites(driverCode: "ccc"))
        #expect(rows.filter(\.isFavorite).map(\.title) == ["CCC"])
        #expect(StandingsTable.scrollTarget(in: rows) == "ccc")
    }

    @Test("favorite team is marked in the teams list")
    func favoriteTeam() {
        let rows = StandingsTable.rows(.teams, in: snapshot, favorites: Favorites(constructorId: "blue"))
        #expect(rows.filter(\.isFavorite).map(\.title) == ["Blue"])
        #expect(StandingsTable.scrollTarget(in: rows) == "blue")
    }

    @Test("no favorite, no scroll target")
    func noFavorite() {
        let rows = StandingsTable.rows(.teams, in: snapshot, favorites: Favorites(driverCode: "AAA"))
        #expect(StandingsTable.scrollTarget(in: rows) == nil)
    }

    @Test("row reads well in VoiceOver")
    func accessibility() {
        let row = StandingsTable.rows(.drivers, in: snapshot, favorites: Favorites(driverCode: "AAA"))[0]
        #expect(row.accessibilityLabel == "Position 1, AAA, AAA AAA · Silver, 292 points, your favorite")
    }
}
