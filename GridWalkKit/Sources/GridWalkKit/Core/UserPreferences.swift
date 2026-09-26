import Foundation

/// The driver and team the user follows.
public struct Favorites: Codable, Sendable, Equatable {
    /// Three-letter code from the feed, e.g. "ANT".
    public var driverCode: String?
    /// Jolpica constructor id, e.g. "mercedes".
    public var constructorId: String?

    public init(driverCode: String? = nil, constructorId: String? = nil) {
        self.driverCode = driverCode
        self.constructorId = constructorId
    }

    public func isFavorite(_ driver: DriverStanding) -> Bool {
        guard let driverCode else { return false }
        return driver.displayCode.caseInsensitiveCompare(driverCode) == .orderedSame || driver.driverId == driverCode
    }

    public func isFavorite(_ team: ConstructorStanding) -> Bool {
        team.constructorId == constructorId
    }
}

/// Everything the user picks in settings or onboarding, saved as one value.
public struct UserPreferences: Codable, Sendable, Equatable {
    public var alerts: AlertPreferences
    public var menuBar: MenuBarPreferences
    public var favorites: Favorites
    public var spoilers: SpoilerPreferences
    public var hasFinishedOnboarding: Bool

    public init(
        alerts: AlertPreferences = AlertPreferences(),
        menuBar: MenuBarPreferences = MenuBarPreferences(),
        favorites: Favorites = Favorites(),
        spoilers: SpoilerPreferences = SpoilerPreferences(),
        hasFinishedOnboarding: Bool = false
    ) {
        self.alerts = alerts
        self.menuBar = menuBar
        self.favorites = favorites
        self.spoilers = spoilers
        self.hasFinishedOnboarding = hasFinishedOnboarding
    }

    // new fields fall back to defaults so an older saved blob still loads
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = UserPreferences()
        alerts = try container.decodeIfPresent(AlertPreferences.self, forKey: .alerts) ?? defaults.alerts
        menuBar = try container.decodeIfPresent(MenuBarPreferences.self, forKey: .menuBar) ?? defaults.menuBar
        favorites = try container.decodeIfPresent(Favorites.self, forKey: .favorites) ?? defaults.favorites
        spoilers = try container.decodeIfPresent(SpoilerPreferences.self, forKey: .spoilers) ?? defaults.spoilers
        hasFinishedOnboarding =
            try container.decodeIfPresent(Bool.self, forKey: .hasFinishedOnboarding)
            ?? defaults.hasFinishedOnboarding
    }
}

/// Loads and saves `UserPreferences`. Main actor because `UserDefaults` isn't `Sendable`.
@MainActor
public protocol PreferencesStoring {
    func load() -> UserPreferences
    func save(_ preferences: UserPreferences)
}

/// `UserDefaults` backed preferences.
@MainActor
public struct DefaultsPreferencesStorage: PreferencesStoring {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "userPreferences") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> UserPreferences {
        guard let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data)
        else {
            return UserPreferences()
        }
        return decoded
    }

    public func save(_ preferences: UserPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: key)
    }
}
