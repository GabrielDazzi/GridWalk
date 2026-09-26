import GridWalkDesign
import GridWalkKit
import SwiftUI
import WidgetKit

struct NextSessionWidgetView: View {
    let entry: NextSessionEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            #if os(iOS)
            // lock screen families are tinted by the system, so no token colors here
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
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.sessionDisplayName)
                        .font(.headline)
                    Text(snapshot.dateUTC, style: .timer)
                        .font(.title3.monospacedDigit())
                    Text(snapshot.weekendName)
                        .font(.caption2)
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
                .foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func smallView(_ snapshot: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                BrandMark(size: 16)
                tag(snapshot)
            }
            countdown(snapshot)
                .font(.title.bold().monospacedDigit())
            Spacer(minLength: 0)
            Text(snapshot.weekendName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.text)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func mediumView(_ snapshot: WidgetSnapshot) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    BrandMark(size: 18)
                    tag(snapshot)
                }
                Text(snapshot.sessionDisplayName)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                Text(snapshot.weekendName)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(2)
                Spacer(minLength: 0)
                FavoriteLine(snapshot: snapshot, date: entry.date)
            }
            Spacer(minLength: 0)
            countdown(snapshot)
                .font(.largeTitle.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func tag(_ snapshot: WidgetSnapshot) -> some View {
        if let kind = snapshot.sessionKind {
            SessionTag(kind)
        }
    }

    private func countdown(_ snapshot: WidgetSnapshot) -> some View {
        Text(snapshot.dateUTC, style: .timer)
            .foregroundStyle(Theme.accent)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .accessibilityLabel(spokenCountdown(snapshot))
    }

    // accurate to the entry date, which is at most 15 minutes old
    private func spokenCountdown(_ snapshot: WidgetSnapshot) -> String {
        guard let kind = snapshot.sessionKind else { return snapshot.sessionDisplayName }
        return CountdownFormat.accessibilityLabel(for: kind, until: snapshot.dateUTC, from: entry.date)
    }
}

struct FavoriteLine: View {
    let snapshot: WidgetSnapshot
    let date: Date

    var body: some View {
        if let favorite = snapshot.visibleFavorite(at: date) {
            Text("\(favorite.name) P\(favorite.position) · \(favorite.points) pts")
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(Theme.text)
        } else if snapshot.isHidingResults(at: date) {
            Label("Results hidden", systemImage: "eye.slash")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryText)
        }
    }
}
