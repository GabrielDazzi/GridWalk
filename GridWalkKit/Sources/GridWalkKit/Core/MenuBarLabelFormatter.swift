import Foundation

/// Text and icon for the Mac menu bar label.
public struct MenuBarLabelContent: Sendable, Equatable {
    public let text: String
    public let compactText: String
    public let systemImage: String?

    public init(text: String, compactText: String? = nil, systemImage: String? = nil) {
        self.text = text
        self.compactText = compactText ?? text
        self.systemImage = systemImage
    }
}

/// Everything the menu bar label needs to decide what to show.
public struct MenuBarContext: Sendable {
    public var nextSession: TimedSession?
    public var races: [RaceWeekend]
    public var standings: StandingsSnapshot?
    public var favorites: Favorites
    /// True while spoiler-free mode is hiding the latest results.
    public var resultsHidden: Bool
    public var now: Date

    public init(
        nextSession: TimedSession?,
        races: [RaceWeekend],
        standings: StandingsSnapshot?,
        favorites: Favorites = Favorites(),
        resultsHidden: Bool = false,
        now: Date = .now
    ) {
        self.nextSession = nextSession
        self.races = races
        self.standings = standings
        self.favorites = favorites
        self.resultsHidden = resultsHidden
        self.now = now
    }
}

/// Picks and formats the menu bar label for a mode.
public enum MenuBarLabelFormatter {
    public static let postRaceWindow: TimeInterval = 36 * 60 * 60
    public static let weekendProximity: TimeInterval = 3 * 24 * 60 * 60

    public static func content(mode: MenuBarMode, context: MenuBarContext) -> MenuBarLabelContent {
        let resolved = resolveMode(mode, context: context)
        return format(mode: resolved, context: context)
            ?? MenuBarLabelContent(text: "Grid Walk", systemImage: "flag.checkered")
    }

    /// The mode to show right now, taking the ticker into account.
    public static func activeMode(preferences: MenuBarPreferences, tick: Int, resultsHidden: Bool) -> MenuBarMode {
        guard preferences.isTickerActive else { return preferences.mode }
        let modes = preferences.tickerModes.filter { !(resultsHidden && $0.revealsResults) }
        guard !modes.isEmpty else { return preferences.mode }
        return modes[abs(tick) % modes.count]
    }

    public static func resolveMode(_ mode: MenuBarMode, context: MenuBarContext) -> MenuBarMode {
        guard mode == .auto else {
            if mode.revealsResults, context.resultsHidden { return .countdown }
            return mode
        }

        if context.resultsHidden || isRaceWeekend(nextSession: context.nextSession, now: context.now) {
            return .countdown
        }

        if let last = context.standings?.lastRace,
            context.now.timeIntervalSince(last.dateUTC) >= 0,
            context.now.timeIntervalSince(last.dateUTC) < postRaceWindow
        {
            return .lastRace
        }

        if context.favorites.driverCode != nil {
            return .myDriver
        }
        return .titleFight
    }

    public static func isRaceWeekend(nextSession: TimedSession?, now: Date) -> Bool {
        guard let next = nextSession else { return false }
        return next.session.dateUTC.timeIntervalSince(now) <= weekendProximity
    }

    public static func format(mode: MenuBarMode, context: MenuBarContext) -> MenuBarLabelContent? {
        if mode.revealsResults, context.resultsHidden { return nil }
        switch mode {
        case .countdown:
            guard let next = context.nextSession else { return nil }
            let full = CountdownFormat.menuBarLabel(session: next.session, from: context.now)
            let compact = CountdownFormat.compact(until: next.session.dateUTC, from: context.now)
            return MenuBarLabelContent(text: full, compactText: compact, systemImage: "timer")

        case .myDriver:
            guard let driver = context.standings?.drivers.first(where: context.favorites.isFavorite) else {
                return MenuBarLabelContent(
                    text: String(localized: "Pick a driver", bundle: .module),
                    compactText: "-",
                    systemImage: "person"
                )
            }
            return MenuBarLabelContent(
                text: driver.shortLabel,
                compactText: "P\(driver.position)",
                systemImage: "person.fill"
            )

        case .titleFight:
            return titleFight(standings: context.standings, races: context.races, now: context.now)

        case .myTeam:
            guard let team = context.standings?.constructors.first(where: context.favorites.isFavorite) else {
                return MenuBarLabelContent(
                    text: String(localized: "Pick a team", bundle: .module),
                    compactText: "-",
                    systemImage: "shield"
                )
            }
            return MenuBarLabelContent(
                text: team.shortLabel,
                compactText: "P\(team.position)",
                systemImage: "shield.fill"
            )

        case .lastRace:
            guard let last = context.standings?.lastRace else { return nil }
            let entry = context.favorites.driverCode.flatMap(last.result(forDriverCode:)) ?? last.winner
            guard let entry else { return nil }
            return MenuBarLabelContent(
                text: "\(entry.displayCode) P\(entry.position)",
                compactText: "P\(entry.position)",
                systemImage: "flag.checkered"
            )

        case .auto:
            return format(mode: resolveMode(.auto, context: context), context: context)
        }
    }

    public static func titleFight(
        standings: StandingsSnapshot?,
        races: [RaceWeekend],
        now: Date
    ) -> MenuBarLabelContent {
        guard let drivers = standings?.drivers, drivers.count >= 2 else {
            return MenuBarLabelContent(
                text: String(localized: "Title fight", bundle: .module),
                compactText: "-",
                systemImage: "trophy"
            )
        }
        let gap = drivers[0].points - drivers[1].points
        let remaining = StandingsMath.remainingRaceWeekends(in: races, now: now)
        let pointsLeft = Double(remaining * 25)

        if remaining == 0 || gap > pointsLeft {
            return MenuBarLabelContent(
                text: String(localized: "Champion", bundle: .module),
                compactText: String(localized: "Champ", bundle: .module, comment: "Short for champion"),
                systemImage: "trophy.fill"
            )
        }

        let gapText = gap == 0 ? "0" : "+\(Int(gap.rounded()))"
        // late season and still catchable
        if pointsLeft <= 75, gap < pointsLeft {
            return MenuBarLabelContent(
                text: String(localized: "Still in the fight · \(gapText)", bundle: .module),
                compactText: gapText,
                systemImage: "trophy"
            )
        }
        return MenuBarLabelContent(text: gapText, compactText: gapText, systemImage: "trophy")
    }
}

extension MenuBarMode {
    /// Modes that show anything that changes after a race.
    public var revealsResults: Bool {
        switch self {
        case .lastRace, .myDriver, .myTeam, .titleFight: true
        case .countdown, .auto: false
        }
    }
}
