import Foundation

/// A page of the first-launch flow.
public enum OnboardingStep: String, Sendable, Hashable, CaseIterable, Identifiable {
    case welcome
    case driver
    case team
    case menuBar
    case notifications

    public var id: String { rawValue }

    /// The menu bar step only makes sense on the Mac.
    public static func steps(includesMenuBar: Bool) -> [OnboardingStep] {
        allCases.filter { $0 != .menuBar || includesMenuBar }
    }
}

/// A driver or team the user can pick. Listed by name, not position, so picking doesn't spoil anything.
public struct FavoriteChoice: Identifiable, Sendable, Hashable {
    /// Value stored in `Favorites`: driver code or constructor id.
    public let id: String
    public let title: String
    public let subtitle: String?
}

public enum OnboardingChoices {
    public static func drivers(in snapshot: StandingsSnapshot?) -> [FavoriteChoice] {
        (snapshot?.drivers ?? [])
            .sorted { ($0.familyName, $0.givenName) < ($1.familyName, $1.givenName) }
            .map {
                FavoriteChoice(
                    id: $0.displayCode,
                    title: "\($0.givenName) \($0.familyName)",
                    subtitle: "\($0.displayCode) · \($0.constructorName)"
                )
            }
    }

    public static func teams(in snapshot: StandingsSnapshot?) -> [FavoriteChoice] {
        (snapshot?.constructors ?? [])
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { FavoriteChoice(id: $0.constructorId, title: $0.name, subtitle: nil) }
    }
}
