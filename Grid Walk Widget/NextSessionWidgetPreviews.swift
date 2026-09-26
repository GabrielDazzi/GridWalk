import GridWalkKit
import SwiftUI
import WidgetKit

private enum WidgetPreviewData {
    static var timed: TimedSession {
        let weekend = SampleData.schedule(around: .now).races[2]
        return TimedSession(weekend: weekend, session: weekend.sessions[3])
    }

    static var favorite: FavoriteSummary {
        FavoriteSummary(name: "OKA", position: 4, points: "26")
    }

    static var visible: NextSessionEntry {
        NextSessionEntry(date: .now, snapshot: WidgetSnapshot(timed: timed, lastUpdated: .now, favorite: favorite))
    }

    static var hidden: NextSessionEntry {
        let snapshot = WidgetSnapshot(
            sessionKindRaw: timed.session.kind.rawValue,
            sessionShortName: timed.session.kind.shortName,
            sessionDisplayName: timed.session.kind.displayName,
            dateUTC: timed.session.dateUTC,
            weekendName: timed.weekend.name,
            isSprintWeekend: true,
            lastUpdated: .now,
            favorite: favorite,
            resultsHiddenUntil: .now.addingTimeInterval(86_400)
        )
        return NextSessionEntry(date: .now, snapshot: snapshot)
    }
}

#Preview("Small", as: .systemSmall) {
    NextSessionWidget()
} timeline: {
    WidgetPreviewData.visible
    NextSessionEntry(date: .now, snapshot: nil)
}

#Preview("Medium", as: .systemMedium) {
    NextSessionWidget()
} timeline: {
    WidgetPreviewData.visible
    WidgetPreviewData.hidden
}
