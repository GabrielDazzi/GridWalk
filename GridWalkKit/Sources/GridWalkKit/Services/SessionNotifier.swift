import Foundation
import UserNotifications

/// One local notification to schedule before a session.
public struct SessionAlert: Sendable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let body: String
    public let fireDate: Date
}

/// Decides which session alerts should exist. Pure, so tests can check it.
public enum SessionAlertPlanner {
    public static let leadTime: TimeInterval = 15 * 60
    /// iOS keeps at most 64 pending notifications per app.
    public static let maximumPending = 64
    static let identifierPrefix = "gridwalk.session."

    public static func alerts(
        races: [RaceWeekend],
        preferences: AlertPreferences,
        now: Date
    ) -> [SessionAlert] {
        let upcoming = races.flatMap { weekend in
            weekend.sessions.compactMap { session -> SessionAlert? in
                guard preferences.isEnabled(session.kind) else { return nil }
                let fireDate = session.dateUTC.addingTimeInterval(-leadTime)
                guard fireDate > now else { return nil }
                return SessionAlert(
                    id: identifierPrefix + session.id,
                    title: session.kind.displayName,
                    body: String(localized: "\(weekend.name) starts in 15 minutes", bundle: .module),
                    fireDate: fireDate
                )
            }
        }
        return Array(upcoming.sorted { $0.fireDate < $1.fireDate }.prefix(maximumPending))
    }
}

/// Local notification access. Faked in tests.
public protocol NotificationScheduling: Sendable {
    func requestAuthorization() async -> Bool
    /// Removes our pending alerts and schedules `alerts` instead.
    func replaceAlerts(with alerts: [SessionAlert]) async
}

/// `UNUserNotificationCenter` backed scheduler.
public struct UserNotificationScheduler: NotificationScheduling {
    public static let categoryIdentifier = "sessionAlert"

    public init() {}

    public func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]))
            ?? false
    }

    public func replaceAlerts(with alerts: [SessionAlert]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(SessionAlertPlanner.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)

        for alert in alerts {
            let content = UNMutableNotificationContent()
            content.title = alert.title
            content.body = alert.body
            content.sound = .default
            content.categoryIdentifier = Self.categoryIdentifier

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: alert.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: alert.id, content: content, trigger: trigger))
        }
    }
}
