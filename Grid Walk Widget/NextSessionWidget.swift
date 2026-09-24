import WidgetKit
import SwiftUI
import GridWalkKit

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
                sessionShortName: "Quali",
                sessionDisplayName: "Qualifying",
                dateUTC: .now.addingTimeInterval(3600),
                weekendName: "Sample Grand Prix",
                isSprintWeekend: false,
                lastUpdated: .now
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextSessionEntry) -> Void) {
        completion(NextSessionEntry(date: .now, snapshot: WidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextSessionEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.load()
        let entry = NextSessionEntry(date: .now, snapshot: snapshot)

        let refresh: Date
        if let start = snapshot?.dateUTC, start > .now {
            // Reload around the session and periodically before that.
            refresh = min(start, .now.addingTimeInterval(15 * 60))
        } else {
            refresh = .now.addingTimeInterval(60 * 60)
        }

        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct NextSessionWidget: Widget {
    let kind = "NextSessionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextSessionProvider()) { entry in
            NextSessionWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0x0E / 255, green: 0x0F / 255, blue: 0x12 / 255)
                }
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

struct NextSessionWidgetView: View {
    let entry: NextSessionEntry
    @Environment(\.widgetFamily) private var family

    private let startRed = Color(red: 1, green: 0.23, blue: 0.19)
    private let pitWhite = Color(red: 0.95, green: 0.95, blue: 0.95)
    private let muted = Color(red: 0.54, green: 0.56, blue: 0.60)

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            #if os(iOS)
            case .accessoryInline:
                Text("\(snapshot.sessionShortName) \(snapshot.dateUTC, style: .timer)")
            case .accessoryCircular:
                VStack(spacing: 2) {
                    Text(snapshot.sessionShortName)
                        .font(.caption2.weight(.bold))
                    Text(snapshot.dateUTC, style: .timer)
                        .font(.caption2.monospacedDigit())
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(pitWhite)
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.sessionDisplayName)
                        .font(.headline)
                    Text(snapshot.dateUTC, style: .timer)
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(startRed)
                    Text(snapshot.weekendName)
                        .font(.caption2)
                        .foregroundStyle(muted)
                        .lineLimit(1)
                }
            #endif
            case .systemSmall:
                smallView(snapshot)
            default:
                mediumView(snapshot)
            }
        } else {
            Text("No upcoming sessions")
                .font(.caption)
                .foregroundStyle(muted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func smallView(_ snapshot: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(snapshot.sessionShortName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(muted)
            Text(snapshot.dateUTC, style: .timer)
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(startRed)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(snapshot.weekendName)
                .font(.caption2)
                .foregroundStyle(pitWhite)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func mediumView(_ snapshot: WidgetSnapshot) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.sessionDisplayName)
                    .font(.headline)
                    .foregroundStyle(pitWhite)
                Text(snapshot.weekendName)
                    .font(.caption)
                    .foregroundStyle(muted)
                    .lineLimit(2)
                if snapshot.isSprintWeekend {
                    Text("Sprint")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(red: 0.2, green: 0.82, blue: 0.96))
                }
            }
            Spacer(minLength: 0)
            Text(snapshot.dateUTC, style: .timer)
                .font(.largeTitle.bold().monospacedDigit())
                .foregroundStyle(startRed)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
