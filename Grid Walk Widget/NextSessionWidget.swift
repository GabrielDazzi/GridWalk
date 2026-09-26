import GridWalkDesign
import GridWalkKit
import SwiftUI
import WidgetKit

struct NextSessionEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct NextSessionProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextSessionEntry {
        NextSessionEntry(
            date: .now,
            snapshot: WidgetSnapshot(
                sessionKindRaw: SessionKind.qualifying.rawValue,
                sessionShortName: SessionKind.qualifying.shortName,
                sessionDisplayName: SessionKind.qualifying.displayName,
                dateUTC: .now.addingTimeInterval(3600),
                weekendName: "Grand Prix",
                isSprintWeekend: false,
                lastUpdated: .now
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextSessionEntry) -> Void) {
        completion(NextSessionEntry(date: .now, snapshot: WidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextSessionEntry>) -> Void) {
        let now = Date.now
        let snapshot = WidgetSnapshotStore.load()
        // extra entries at the spoiler reveal and the session start, so the widget flips without the app running
        let moments = [now] + (snapshot?.timelineDates(after: now) ?? [])
        let entries = moments.map { NextSessionEntry(date: $0, snapshot: snapshot) }

        let refresh: Date
        if let start = snapshot?.dateUTC, start > now {
            refresh = min(start, now.addingTimeInterval(15 * 60))
        } else {
            refresh = now.addingTimeInterval(60 * 60)
        }
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }
}

struct NextSessionWidget: Widget {
    let kind = "NextSessionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextSessionProvider()) { entry in
            NextSessionWidgetView(entry: entry)
                .containerBackground(for: .widget) { Theme.background }
        }
        .configurationDisplayName(String(localized: "Next session"))
        .description(String(localized: "Countdown to the next race weekend session."))
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        #if os(iOS)
        [.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline]
        #else
        [.systemSmall, .systemMedium]
        #endif
    }
}
