import Foundation

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

public enum MenuBarLabelFormatter {
    public static let postRaceWindow: TimeInterval = 36 * 60 * 60
    public static let weekendProximity: TimeInterval = 3 * 24 * 60 * 60

    public static func content(
        mode: MenuBarMode,
        prefs: MenuBarPreferences,
        nextSession: TimedSession?,
        races: [RaceWeekend],
        standings: StandingsSnapshot?,
        now: Date = .now
    ) -> MenuBarLabelContent {
        let resolved = resolveMode(
            mode,
            prefs: prefs,
            nextSession: nextSession,
            races: races,
            standings: standings,
            now: now
        )
        return format(
            mode: resolved,
            prefs: prefs,
            nextSession: nextSession,
            races: races,
            standings: standings,
            now: now
        ) ?? MenuBarLabelContent(text: "Grid Walk", systemImage: "flag.checkered")
    }

    public static func resolveMode(
        _ mode: MenuBarMode,
        prefs: MenuBarPreferences,
        nextSession: TimedSession?,
        races: [RaceWeekend],
        standings: StandingsSnapshot?,
        now: Date = .now
    ) -> MenuBarMode {
        guard mode == .auto else {
            if mode == .lastRace, prefs.spoilerFree { return .countdown }
            return mode
        }

        if isRaceWeekend(nextSession: nextSession, now: now) {
            return .countdown
        }

        if !prefs.spoilerFree,
            let last = standings?.lastRace,
            now.timeIntervalSince(last.dateUTC) >= 0,
            now.timeIntervalSince(last.dateUTC) < postRaceWindow
        {
            return .lastRace
        }

        if prefs.favoriteDriverCode != nil {
            return .myDriver
        }
        return .titleFight
    }

    public static func isRaceWeekend(nextSession: TimedSession?, now: Date) -> Bool {
        guard let next = nextSession else { return false }
        return next.session.dateUTC.timeIntervalSince(now) <= weekendProximity
    }

    public static func format(
        mode: MenuBarMode,
        prefs: MenuBarPreferences,
        nextSession: TimedSession?,
        races: [RaceWeekend],
        standings: StandingsSnapshot?,
        now: Date = .now
    ) -> MenuBarLabelContent? {
        switch mode {
        case .countdown:
            guard let next = nextSession else { return nil }
            let full = CountdownFormat.menuBarLabel(session: next.session, from: now)
            let compact = CountdownFormat.compact(until: next.session.dateUTC, from: now)
            return MenuBarLabelContent(text: full, compactText: compact, systemImage: "timer")

        case .myDriver:
            guard let code = prefs.favoriteDriverCode,
                let driver = standings?.drivers.first(where: {
                    $0.displayCode.caseInsensitiveCompare(code) == .orderedSame
                        || $0.driverId == code
                })
            else {
                return MenuBarLabelContent(text: "Pick a driver", compactText: "—", systemImage: "person")
            }
            return MenuBarLabelContent(
                text: driver.shortLabel,
                compactText: "P\(driver.position)",
                systemImage: "person.fill"
            )

        case .titleFight:
            return titleFight(standings: standings, races: races, now: now)

        case .myTeam:
            guard let id = prefs.favoriteConstructorId,
                let team = standings?.constructors.first(where: { $0.constructorId == id })
            else {
                return MenuBarLabelContent(text: "Pick a team", compactText: "—", systemImage: "shield")
            }
            return MenuBarLabelContent(
                text: "\(team.name) P\(team.position) · \(team.pointsString)",
                compactText: "P\(team.position)",
                systemImage: "shield.fill"
            )

        case .lastRace:
            if prefs.spoilerFree { return nil }
            guard let last = standings?.lastRace else { return nil }
            let entry: RaceResultEntry?
            if let code = prefs.favoriteDriverCode {
                entry = last.result(forDriverCode: code) ?? last.winner
            } else {
                entry = last.winner
            }
            guard let entry else { return nil }
            return MenuBarLabelContent(
                text: "\(entry.displayCode) P\(entry.position)",
                compactText: "P\(entry.position)",
                systemImage: "flag.checkered"
            )

        case .auto:
            let resolved = resolveMode(
                .auto,
                prefs: prefs,
                nextSession: nextSession,
                races: races,
                standings: standings,
                now: now
            )
            return format(
                mode: resolved,
                prefs: prefs,
                nextSession: nextSession,
                races: races,
                standings: standings,
                now: now
            )
        }
    }

    public static func titleFight(
        standings: StandingsSnapshot?,
        races: [RaceWeekend],
        now: Date
    ) -> MenuBarLabelContent {
        guard let drivers = standings?.drivers, drivers.count >= 2 else {
            return MenuBarLabelContent(text: "Title fight", compactText: "—", systemImage: "trophy")
        }
        let leader = drivers[0]
        let second = drivers[1]
        let gap = leader.points - second.points
        let remaining = StandingsMath.remainingRaceWeekends(in: races, now: now)
        let pointsLeft = Double(remaining * 25)

        if remaining == 0 || pointsLeft <= 0 {
            return MenuBarLabelContent(
                text: "Champion",
                compactText: "Champ",
                systemImage: "trophy.fill"
            )
        }

        if gap > pointsLeft {
            return MenuBarLabelContent(
                text: "Champion",
                compactText: "Champ",
                systemImage: "trophy.fill"
            )
        }

        // Close enough that second can still catch — or gap is small late season
        if pointsLeft <= 75, gap <= pointsLeft {
            let gapText = gap == 0 ? "0" : "+\(Int(gap.rounded()))"
            if gap < pointsLeft {
                return MenuBarLabelContent(
                    text: "Still in the fight · \(gapText)",
                    compactText: gapText,
                    systemImage: "trophy"
                )
            }
        }

        let gapText = gap == 0 ? "0" : "+\(Int(gap.rounded()))"
        return MenuBarLabelContent(
            text: gapText,
            compactText: gapText,
            systemImage: "trophy"
        )
    }
}
