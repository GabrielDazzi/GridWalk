import Foundation

/// Which session types get a local notification.
public struct AlertPreferences: Codable, Sendable, Equatable {
    public var enabled: Set<AlertCategory>

    public init(enabled: Set<AlertCategory> = AlertCategory.defaultEnabled) {
        self.enabled = enabled
    }

    public func isEnabled(_ kind: SessionKind) -> Bool {
        enabled.contains(kind.alertCategory)
    }

    public mutating func set(_ category: AlertCategory, enabled isOn: Bool) {
        if isOn {
            enabled.insert(category)
        } else {
            enabled.remove(category)
        }
    }
}

public final class AlertPreferencesStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "alertPreferences"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var preferences: AlertPreferences {
        get {
            guard let data = defaults.data(forKey: key),
                let decoded = try? JSONDecoder().decode(AlertPreferences.self, from: data)
            else {
                return AlertPreferences()
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
