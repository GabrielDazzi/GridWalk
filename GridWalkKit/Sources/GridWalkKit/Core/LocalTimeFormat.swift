import Foundation

/// Session times in the user's time zone. Feed times are UTC; this is the only place they turn local.
public enum LocalTimeFormat {
    /// e.g. "Mar 8, 2026 at 1:00 AM"
    public static func sessionDateTime(
        _ date: Date,
        timeZone: TimeZone = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, locale: locale, timeZone: timeZone))
    }

    /// e.g. "1:00 AM"
    public static func sessionTime(
        _ date: Date,
        timeZone: TimeZone = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, timeZone: timeZone))
    }

    /// e.g. "Sunday, Mar 8"
    public static func weekday(
        _ date: Date,
        timeZone: TimeZone = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        var style = Date.FormatStyle(locale: locale, timeZone: timeZone)
        style = style.weekday(.wide).day().month(.abbreviated)
        return date.formatted(style)
    }

    /// Short weekday for timeline rows, e.g. "Sat".
    public static func shortWeekday(
        _ date: Date,
        timeZone: TimeZone = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        date.formatted(Date.FormatStyle(locale: locale, timeZone: timeZone).weekday(.abbreviated))
    }

    /// Wall clock parts of `date` in `timeZone`.
    public static func components(of date: Date, in timeZone: TimeZone) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    }
}
