@preconcurrency import EventKit
import Foundation

/// Why adding a weekend to Calendar failed.
public enum CalendarExportError: Error, Sendable, Equatable {
    case accessDenied
    case noCalendar
    case saveFailed
}

extension CalendarExportError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .accessDenied: "Calendar access is off. Turn it on in Settings to add sessions."
        case .noCalendar: "There's no calendar to add events to."
        case .saveFailed: "Couldn't save the sessions to Calendar."
        }
    }
}

/// Adds a race weekend's sessions to the user's calendar.
@MainActor
public protocol CalendarExporting: AnyObject {
    func addWeekend(_ weekend: RaceWeekend) async throws(CalendarExportError) -> Int
}

/// EventKit backed exporter. Asks for write-only access.
@MainActor
public final class WeekendCalendarExporter: CalendarExporting {
    private let store: EKEventStore

    public init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    public func addWeekend(_ weekend: RaceWeekend) async throws(CalendarExportError) -> Int {
        let granted = (try? await store.requestWriteOnlyAccessToEvents()) ?? false
        guard granted else { throw .accessDenied }
        guard let calendar = store.defaultCalendarForNewEvents else { throw .noCalendar }

        for session in weekend.sessions {
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = "\(session.kind.displayName) · \(weekend.name)"
            event.startDate = session.dateUTC
            event.endDate = session.dateUTC.addingTimeInterval(session.kind.typicalDuration)
            event.notes = "\(weekend.circuitName), \(weekend.locality), \(weekend.country)"
            event.timeZone = .current
            do {
                try store.save(event, span: .thisEvent, commit: false)
            } catch {
                throw .saveFailed
            }
        }
        do {
            try store.commit()
        } catch {
            throw .saveFailed
        }
        return weekend.sessions.count
    }
}

extension SessionKind {
    /// Rough length so the calendar block looks right.
    public var typicalDuration: TimeInterval {
        switch self {
        case .practice1, .practice2, .practice3, .qualifying: 60 * 60
        case .sprintQualifying, .sprint: 45 * 60
        case .race: 2 * 60 * 60
        }
    }
}
