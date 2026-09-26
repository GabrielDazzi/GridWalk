import Foundation

/// What the Mac menu bar label shows.
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
        case .countdown: String(localized: "Countdown", bundle: .module)
        case .myDriver: String(localized: "My driver", bundle: .module)
        case .titleFight: String(localized: "Title fight", bundle: .module)
        case .myTeam: String(localized: "My team", bundle: .module)
        case .lastRace: String(localized: "Last race", bundle: .module)
        case .auto: String(localized: "Auto", bundle: .module, comment: "Menu bar mode that picks for you")
        }
    }
}

/// Menu bar label settings (Mac only).
public struct MenuBarPreferences: Codable, Sendable, Equatable {
    public static let maximumTickerModes = 3

    public var mode: MenuBarMode
    /// Modes to rotate when the ticker is on (2 or 3).
    public private(set) var tickerModes: [MenuBarMode]
    public var tickerEnabled: Bool
    public var tickerIntervalSeconds: Double
    public var compactStyle: Bool

    public init(
        mode: MenuBarMode = .auto,
        tickerModes: [MenuBarMode] = [],
        tickerEnabled: Bool = false,
        tickerIntervalSeconds: Double = 4,
        compactStyle: Bool = false
    ) {
        self.mode = mode
        self.tickerModes = Self.sanitized(tickerModes)
        self.tickerEnabled = tickerEnabled
        self.tickerIntervalSeconds = tickerIntervalSeconds
        self.compactStyle = compactStyle
    }

    public var isTickerActive: Bool {
        tickerEnabled && tickerModes.count >= 2
    }

    public mutating func setTickerModes(_ modes: [MenuBarMode]) {
        tickerModes = Self.sanitized(modes)
        tickerEnabled = tickerModes.count >= 2
    }

    /// Adds or removes one ticker mode, ignoring adds past the limit.
    public mutating func setTicker(_ mode: MenuBarMode, included: Bool) {
        var modes = tickerModes
        if included {
            guard !modes.contains(mode), modes.count < Self.maximumTickerModes else { return }
            modes.append(mode)
        } else {
            modes.removeAll { $0 == mode }
        }
        setTickerModes(modes)
    }

    private static func sanitized(_ modes: [MenuBarMode]) -> [MenuBarMode] {
        var seen: Set<MenuBarMode> = []
        let unique = modes.filter { $0 != .auto && seen.insert($0).inserted }
        return Array(unique.prefix(maximumTickerModes))
    }
}
