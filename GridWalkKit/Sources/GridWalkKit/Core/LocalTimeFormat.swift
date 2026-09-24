import Foundation

public enum LocalTimeFormat {
    private static let sessionFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.timeZone = .autoupdatingCurrent
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private static let timeOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.timeZone = .autoupdatingCurrent
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.timeZone = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("EEEEdMMM")
        return f
    }()

    public static func sessionDateTime(_ date: Date, timeZone: TimeZone = .autoupdatingCurrent) -> String {
        sessionFormatter.timeZone = timeZone
        return sessionFormatter.string(from: date)
    }

    public static func sessionTime(_ date: Date, timeZone: TimeZone = .autoupdatingCurrent) -> String {
        timeOnlyFormatter.timeZone = timeZone
        return timeOnlyFormatter.string(from: date)
    }

    public static func weekday(_ date: Date, timeZone: TimeZone = .autoupdatingCurrent) -> String {
        weekdayFormatter.timeZone = timeZone
        return weekdayFormatter.string(from: date)
    }

    /// Instant in `timeZone` for display math / tests.
    public static func components(of date: Date, in timeZone: TimeZone) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    }
}
