import Foundation

public enum CountdownFormat {
    /// e.g. "1d 4h", "42m"
    public static func compact(until date: Date, from now: Date = .now) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(now)))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        }
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    public static func menuBarLabel(session: Session, from now: Date = .now) -> String {
        "\(session.kind.shortName) · \(compact(until: session.dateUTC, from: now))"
    }
}
