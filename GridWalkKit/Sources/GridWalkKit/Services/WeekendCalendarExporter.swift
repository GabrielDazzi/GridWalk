@preconcurrency import EventKit
import Foundation

public enum WeekendCalendarError: Error, Sendable {
    case accessDenied
    case noCalendar
}

@MainActor
public final class WeekendCalendarExporter {
    private let store: EKEventStore

    public init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    public func requestAccess() async throws {
        let granted = try await store.requestWriteOnlyAccessToEvents()
        guard granted else { throw WeekendCalendarError.accessDenied }
    }

    @discardableResult
    public func addWeekend(_ weekend: RaceWeekend) async throws -> Int {
        try await requestAccess()

        guard let calendar = store.defaultCalendarForNewEvents else {
            throw WeekendCalendarError.noCalendar
        }

        var created = 0
        for session in weekend.sessions {
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = "\(session.kind.displayName) · \(weekend.name)"
            event.startDate = session.dateUTC
            // Rough length so the block shows on the calendar
            event.endDate = session.dateUTC.addingTimeInterval(duration(for: session.kind))
            event.notes = "\(weekend.circuitName), \(weekend.locality), \(weekend.country)"
            event.timeZone = .current
            try store.save(event, span: .thisEvent)
            created += 1
        }
        return created
    }

    private func duration(for kind: SessionKind) -> TimeInterval {
        switch kind {
        case .practice1, .practice2, .practice3: 60 * 60
        case .sprintQualifying: 45 * 60
        case .sprint: 45 * 60
        case .qualifying: 60 * 60
        case .race: 2 * 60 * 60
        }
    }
}
