import Foundation
import Testing

@testable import GridWalkKit

@Suite("Countdown math")
struct CountdownMathTests {
    private let start = Date(timeIntervalSince1970: 1_780_000_000)

    @Test(
        "splits into days, hours, minutes, seconds",
        arguments: [
            (90_061.0, CountdownParts.Expected(days: 1, hours: 1, minutes: 1, seconds: 1)),
            (59.0, .init(days: 0, hours: 0, minutes: 0, seconds: 59)),
            (3_600.0, .init(days: 0, hours: 1, minutes: 0, seconds: 0)),
            (-30.0, .init(days: 0, hours: 0, minutes: 0, seconds: 0)),
        ]
    )
    func parts(offset: TimeInterval, expected: CountdownParts.Expected) {
        let parts = CountdownParts(until: start.addingTimeInterval(offset), from: start)
        #expect(parts.days == expected.days)
        #expect(parts.hours == expected.hours)
        #expect(parts.minutes == expected.minutes)
        #expect(parts.seconds == expected.seconds)
    }

    @Test("past sessions are finished, never negative")
    func finished() {
        #expect(CountdownParts(until: start, from: start.addingTimeInterval(10)).isFinished)
        #expect(CountdownFormat.compact(until: start, from: start.addingTimeInterval(10)) == "0m")
    }

    @Test("compact format picks the two largest units")
    func compact() {
        #expect(CountdownFormat.compact(until: start.addingTimeInterval(90_000), from: start) == "1d 1h")
        #expect(CountdownFormat.compact(until: start.addingTimeInterval(3 * 3600 + 12 * 60), from: start) == "3h 12m")
        #expect(CountdownFormat.compact(until: start.addingTimeInterval(42 * 60), from: start) == "42m")
    }

    @Test("DST change doesn't add or lose an hour")
    func acrossSpringForward() throws {
        // US clocks jump 02:00 -> 03:00 on 2026-03-08; 24 real hours is still "1d 0h"
        let before = try utcDate("2026-03-07T12:00:00Z")
        let after = before.addingTimeInterval(24 * 3600)
        #expect(CountdownFormat.compact(until: after, from: before) == "1d 0h")

        let newYork = try #require(TimeZone(identifier: "America/New_York"))
        let beforeWall = LocalTimeFormat.components(of: before, in: newYork)
        let afterWall = LocalTimeFormat.components(of: after, in: newYork)
        #expect(beforeWall.hour == 7)
        #expect(afterWall.hour == 8)
    }
}

extension CountdownParts {
    struct Expected: Sendable {
        let days: Int
        let hours: Int
        let minutes: Int
        let seconds: Int
    }
}

@Suite("Countdown for VoiceOver")
struct CountdownAccessibilityTests {
    private let now = Date(timeIntervalSince1970: 1_780_000_000)
    private let english = Locale(identifier: "en_US")

    @Test("spells out days and hours")
    func daysAndHours() {
        let text = CountdownFormat.spokenDuration(
            until: now.addingTimeInterval(28 * 3600 + 120), from: now, locale: english)
        #expect(text == "1 day, 4 hours")
    }

    @Test("drops zero units")
    func dropsZero() {
        #expect(
            CountdownFormat.spokenDuration(until: now.addingTimeInterval(3600), from: now, locale: english) == "1 hour")
        #expect(
            CountdownFormat.spokenDuration(until: now.addingTimeInterval(125 * 60), from: now, locale: english)
                == "2 hours, 5 minutes"
        )
    }

    @Test("label names the session")
    func label() {
        let text = CountdownFormat.accessibilityLabel(
            for: .qualifying,
            until: now.addingTimeInterval(28 * 3600),
            from: now
        )
        #expect(text.hasPrefix("Qualifying in "))
        #expect(text.contains("day"))
        let live = CountdownFormat.accessibilityLabel(for: .race, until: now.addingTimeInterval(20), from: now)
        #expect(live == "Race is starting now")
    }
}

@Suite("Local time")
struct LocalTimeTests {
    private let english = Locale(identifier: "en_US")

    @Test("same instant, different wall clocks")
    func timeZones() throws {
        // Las Vegas race: Saturday night local, Sunday morning UTC
        let race = try utcDate("2026-11-22T04:00:00Z")
        let vegas = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        #expect(LocalTimeFormat.shortWeekday(race, timeZone: vegas, locale: english) == "Sat")
        #expect(LocalTimeFormat.shortWeekday(race, timeZone: .gmt, locale: english) == "Sun")
        #expect(LocalTimeFormat.sessionTime(race, timeZone: vegas, locale: english) == "8:00\u{202F}PM")
        #expect(LocalTimeFormat.sessionTime(race, timeZone: tokyo, locale: english) == "1:00\u{202F}PM")
    }

    @Test("DST: same UTC hour lands on different local hours")
    func daylightSaving() throws {
        let london = try #require(TimeZone(identifier: "Europe/London"))
        let winter = try utcDate("2026-03-22T14:00:00Z")
        let summer = try utcDate("2026-04-05T14:00:00Z")
        #expect(LocalTimeFormat.components(of: winter, in: london).hour == 14)
        #expect(LocalTimeFormat.components(of: summer, in: london).hour == 15)
    }

    @Test("formats in Portuguese when asked")
    func portuguese() throws {
        let date = try utcDate("2026-03-08T04:00:00Z")
        let text = LocalTimeFormat.weekday(date, timeZone: .gmt, locale: Locale(identifier: "pt_BR"))
        #expect(text.lowercased().contains("domingo"))
    }
}
