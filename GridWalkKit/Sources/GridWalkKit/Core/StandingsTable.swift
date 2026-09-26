import Foundation

/// One ready-to-draw row of a standings list.
public struct StandingsRowModel: Identifiable, Sendable, Hashable {
    public let id: String
    public let position: Int
    /// Driver code or team name, the bold part of the row.
    public let title: String
    /// Driver full name plus team, or nil for teams.
    public let subtitle: String?
    public let points: String
    /// e.g. "-42", nil for the leader.
    public let gapToLeader: String?
    public let isFavorite: Bool

    public init(
        id: String,
        position: Int,
        title: String,
        subtitle: String?,
        points: String,
        gapToLeader: String?,
        isFavorite: Bool
    ) {
        self.id = id
        self.position = position
        self.title = title
        self.subtitle = subtitle
        self.points = points
        self.gapToLeader = gapToLeader
        self.isFavorite = isFavorite
    }

    /// VoiceOver text, e.g. "Position 1, ANT, Andrea Kimi Antonelli, 292 points, your favorite".
    public var accessibilityLabel: String {
        var parts = [String(localized: "Position \(position)", bundle: .module), title]
        if let subtitle { parts.append(subtitle) }
        parts.append(String(localized: "\(points) points", bundle: .module))
        if isFavorite { parts.append(String(localized: "your favorite", bundle: .module)) }
        return parts.joined(separator: ", ")
    }
}

/// Which standings list to show.
public enum StandingsKind: String, Sendable, CaseIterable, Identifiable {
    case drivers
    case teams

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .drivers: String(localized: "Drivers", bundle: .module)
        case .teams: String(localized: "Teams", bundle: .module)
        }
    }
}

/// Builds standings rows with the user's favorites marked.
public enum StandingsTable {
    public static func rows(_ kind: StandingsKind, in snapshot: StandingsSnapshot, favorites: Favorites)
        -> [StandingsRowModel]
    {
        switch kind {
        case .drivers: driverRows(snapshot.drivers, favorites: favorites)
        case .teams: teamRows(snapshot.constructors, favorites: favorites)
        }
    }

    public static func driverRows(_ drivers: [DriverStanding], favorites: Favorites) -> [StandingsRowModel] {
        let leader = drivers.map(\.points).max() ?? 0
        return drivers.sorted { $0.position < $1.position }.map { driver in
            StandingsRowModel(
                id: driver.id,
                position: driver.position,
                title: driver.displayCode,
                subtitle: "\(driver.givenName) \(driver.familyName) · \(driver.constructorName)",
                points: driver.pointsString,
                gapToLeader: gap(driver.points, leader: leader),
                isFavorite: favorites.isFavorite(driver)
            )
        }
    }

    public static func teamRows(_ teams: [ConstructorStanding], favorites: Favorites) -> [StandingsRowModel] {
        let leader = teams.map(\.points).max() ?? 0
        return teams.sorted { $0.position < $1.position }.map { team in
            StandingsRowModel(
                id: team.id,
                position: team.position,
                title: team.name,
                subtitle: nil,
                points: team.pointsString,
                gapToLeader: gap(team.points, leader: leader),
                isFavorite: favorites.isFavorite(team)
            )
        }
    }

    /// Row to scroll to when the list appears.
    public static func scrollTarget(in rows: [StandingsRowModel]) -> StandingsRowModel.ID? {
        rows.first(where: \.isFavorite)?.id
    }

    private static func gap(_ points: Double, leader: Double) -> String? {
        let difference = leader - points
        guard difference > 0 else { return nil }
        let rounded = difference.rounded()
        return difference == rounded ? "-\(Int(rounded))" : String(format: "-%.1f", difference)
    }
}
