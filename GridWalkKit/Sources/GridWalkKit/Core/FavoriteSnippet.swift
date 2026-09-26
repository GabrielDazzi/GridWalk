import Foundation

/// The small "your driver / your team" block on the home screen and the Mac popover.
public enum FavoriteSnippet: Sendable, Hashable {
    /// Spoiler-free is hiding this weekend.
    case hidden(weekend: RaceWeekend, revealDate: Date?)
    /// Favorite driver row first, then the favorite team row.
    case rows([StandingsRowModel])
    /// Standings are loaded but nothing is picked, or the picks aren't in this season's table.
    case pickFavorites
    /// No standings yet: first launch offline, or pre-season.
    case unavailable

    public static func make(
        snapshot: StandingsSnapshot?,
        favorites: Favorites,
        spoilers: SpoilerState
    ) -> FavoriteSnippet {
        if let weekend = spoilers.hiddenWeekend {
            return .hidden(weekend: weekend, revealDate: spoilers.revealDate)
        }
        guard let snapshot, !snapshot.drivers.isEmpty || !snapshot.constructors.isEmpty else {
            return .unavailable
        }
        let drivers = StandingsTable.driverRows(snapshot.drivers, favorites: favorites).filter(\.isFavorite)
        let teams = StandingsTable.teamRows(snapshot.constructors, favorites: favorites).filter(\.isFavorite)
        let rows = drivers.prefix(1) + teams.prefix(1)
        return rows.isEmpty ? .pickFavorites : .rows(Array(rows))
    }
}
