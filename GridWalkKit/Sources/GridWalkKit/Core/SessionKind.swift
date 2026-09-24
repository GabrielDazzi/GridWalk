import Foundation

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
        case .practice1: "Practice 1"
        case .practice2: "Practice 2"
        case .practice3: "Practice 3"
        case .sprintQualifying: "Sprint Qualifying"
        case .sprint: "Sprint"
        case .qualifying: "Qualifying"
        case .race: "Race"
        }
    }

    /// Compact label for the menu bar.
    public var shortName: String {
        switch self {
        case .practice1: "FP1"
        case .practice2: "FP2"
        case .practice3: "FP3"
        case .sprintQualifying: "SQ"
        case .sprint: "Sprint"
        case .qualifying: "Quali"
        case .race: "Race"
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
}

/// Toggle groups for session alerts.
public enum AlertCategory: String, Codable, Sendable, CaseIterable, Hashable {
    case practice
    case sprint
    case qualifying
    case race

    public var displayName: String {
        switch self {
        case .practice: "Practice"
        case .sprint: "Sprint"
        case .qualifying: "Qualifying"
        case .race: "Race"
        }
    }

    public static var defaultEnabled: Set<AlertCategory> {
        [.sprint, .qualifying, .race]
    }
}
