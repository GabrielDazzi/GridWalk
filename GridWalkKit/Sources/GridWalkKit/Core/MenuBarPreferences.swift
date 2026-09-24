import Foundation

public enum MenuBarMode: String, Codable, Sendable, CaseIterable, Hashable, Identifiable {
    case countdown
    case myDriver
    case titleFight
    case myTeam
    case lastRace
    case auto

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .countdown: "Countdown"
        case .myDriver: "My driver"
        case .titleFight: "Title fight"
        case .myTeam: "My team"
        case .lastRace: "Last race"
        case .auto: "Auto"
        }
    }
}

public struct MenuBarPreferences: Codable, Sendable, Equatable {
    public var mode: MenuBarMode
    /// Modes to rotate when ticker is on (2–3). Empty disables ticker.
    public var tickerModes: [MenuBarMode]
    public var tickerEnabled: Bool
    public var tickerIntervalSeconds: Double
    public var compactStyle: Bool
    public var favoriteDriverCode: String?
    public var favoriteConstructorId: String?
    public var spoilerFree: Bool

    public init(
        mode: MenuBarMode = .auto,
        tickerModes: [MenuBarMode] = [],
        tickerEnabled: Bool = false,
        tickerIntervalSeconds: Double = 4,
        compactStyle: Bool = false,
        favoriteDriverCode: String? = nil,
        favoriteConstructorId: String? = nil,
        spoilerFree: Bool = false
    ) {
        self.mode = mode
        self.tickerModes = Array(tickerModes.prefix(3))
        self.tickerEnabled = tickerEnabled
        self.tickerIntervalSeconds = tickerIntervalSeconds
        self.compactStyle = compactStyle
        self.favoriteDriverCode = favoriteDriverCode
        self.favoriteConstructorId = favoriteConstructorId
        self.spoilerFree = spoilerFree
    }

    public mutating func setTickerModes(_ modes: [MenuBarMode]) {
        tickerModes = Array(modes.filter { $0 != .auto }.prefix(3))
        tickerEnabled = tickerModes.count >= 2
    }
}

public final class MenuBarPreferencesStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "menuBarPreferences"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var preferences: MenuBarPreferences {
        get {
            guard let data = defaults.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(MenuBarPreferences.self, from: data)
            else {
                return MenuBarPreferences()
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: key)
            }
        }
    }
}
