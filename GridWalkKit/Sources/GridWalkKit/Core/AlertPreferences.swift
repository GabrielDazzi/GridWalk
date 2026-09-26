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
