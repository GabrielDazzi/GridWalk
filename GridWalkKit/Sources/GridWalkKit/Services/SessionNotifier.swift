import Foundation
import UserNotifications

public enum SessionNotifier {
    public static let categoryID = "sessionAlert"
    private static let idPrefix = "gridwalk.session."

    /// Clear ours, then schedule up to 64 pending (iOS hard cap).
    public static func reschedule(
        races: [RaceWeekend],
        preferences: AlertPreferences,
        center: UNUserNotificationCenter = .current(),
        now: Date = .now,
        leadTime: TimeInterval = 15 * 60,
        maxPending: Int = 64
    ) async {
        await removeOurs(center: center)

        let candidates: [(session: Session, weekend: RaceWeekend, fireAt: Date)] =
            races
            .flatMap { weekend in
                weekend.sessions.compactMap { session -> (Session, RaceWeekend, Date)? in
                    guard preferences.isEnabled(session.kind) else { return nil }
                    let fireAt = session.dateUTC.addingTimeInterval(-leadTime)
                    guard fireAt > now else { return nil }
                    return (session, weekend, fireAt)
                }
            }
            .sorted { $0.2 < $1.2 }

        for item in candidates.prefix(maxPending) {
            let content = UNMutableNotificationContent()
            content.title = item.session.kind.displayName
            content.body = "\(item.weekend.name) starts in 15 minutes"
            content.sound = .default
            content.categoryIdentifier = categoryID

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: item.fireAt
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let id = idPrefix + item.session.id
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    public static func requestAuthorization(center: UNUserNotificationCenter = .current()) async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    private static func removeOurs(center: UNUserNotificationCenter) async {
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        center.removeDeliveredNotifications(withIdentifiers: ours)
    }
}
