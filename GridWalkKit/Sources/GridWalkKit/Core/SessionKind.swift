import Foundation

/// A timed session in a race weekend.
public enum SessionKind: String, Codable, Sendable, CaseIterable, Hashable {
    case practice1
    case practice2
    case practice3
    case sprintQualifying
    case sprint
    case qualifying
    case race

    public var displayName: String {
        switch self {
        case .practice1: String(localized: "Practice 1", bundle: .module)
        case .practice2: String(localized: "Practice 2", bundle: .module)
        case .practice3: String(localized: "Practice 3", bundle: .module)
        case .sprintQualifying: String(localized: "Sprint Qualifying", bundle: .module)
        case .sprint: String(localized: "Sprint", bundle: .module)
        case .qualifying: String(localized: "Qualifying", bundle: .module)
        case .race: String(localized: "Race", bundle: .module)
        }
    }

    /// Compact label for the menu bar and tags.
    public var shortName: String {
        switch self {
        case .practice1: String(localized: "FP1", bundle: .module, comment: "Short name for Practice 1")
        case .practice2: String(localized: "FP2", bundle: .module, comment: "Short name for Practice 2")
        case .practice3: String(localized: "FP3", bundle: .module, comment: "Short name for Practice 3")
        case .sprintQualifying: String(localized: "SQ", bundle: .module, comment: "Short name for Sprint Qualifying")
        case .sprint: String(localized: "Sprint", bundle: .module)
        case .qualifying: String(localized: "Quali", bundle: .module, comment: "Short name for Qualifying")
        case .race: String(localized: "Race", bundle: .module)
        }
    }

    public var alertCategory: AlertCategory {
        switch self {
        case .practice1, .practice2, .practice3: .practice
        case .sprintQualifying, .sprint: .sprint
        case .qualifying: .qualifying
        case .race: .race
        }
    }

    /// Sessions whose outcome changes results or standings.
    public var isScoring: Bool {
        self == .sprint || self == .race
    }

    /// Rough session length, for calendar blocks and "live now".
    public var typicalDuration: TimeInterval {
        switch self {
        case .practice1, .practice2, .practice3, .qualifying: 60 * 60
        case .sprintQualifying, .sprint: 45 * 60
        case .race: 2 * 60 * 60
        }
    }
}

/// Toggle groups for session alerts. Also drives the session tag color.
public enum AlertCategory: String, Codable, Sendable, CaseIterable, Hashable {
    case practice
    case sprint
    case qualifying
    case race

    public var displayName: String {
        switch self {
        case .practice: String(localized: "Practice", bundle: .module)
        case .sprint: String(localized: "Sprint", bundle: .module)
        case .qualifying: String(localized: "Qualifying", bundle: .module)
        case .race: String(localized: "Race", bundle: .module)
        }
    }

    /// One or two letters shown on the session tag, so color is never the only cue.
    public var tagLetters: String {
        switch self {
        case .practice: String(localized: "FP", bundle: .module, comment: "Tag letters for practice sessions")
        case .sprint: String(localized: "S", bundle: .module, comment: "Tag letter for sprint sessions")
        case .qualifying: String(localized: "Q", bundle: .module, comment: "Tag letter for qualifying")
        case .race: String(localized: "R", bundle: .module, comment: "Tag letter for the race")
        }
    }

    public static var defaultEnabled: Set<AlertCategory> {
        [.sprint, .qualifying, .race]
    }
}
