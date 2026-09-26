import GridWalkKit
import SwiftUI

struct StandingsView: View {
    @Bindable var model: AppModel
    @State private var kind: StandingsKind = .drivers

    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(spacing: 12) {
                Picker("Standings", selection: $kind) {
                    ForEach(StandingsKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                content(now: context.date)
            }
        }
        .padding()
        .background(GridTheme.asphalt)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let spoilers = model.spoilerState(at: now)
        if let weekend = spoilers.hiddenWeekend {
            ResultsHiddenCard(weekendName: weekend.name, revealDate: spoilers.revealDate) {
                model.revealResults(at: now)
            }
            Spacer()
        } else if let snapshot = model.standings.snapshot, !snapshot.drivers.isEmpty {
            StandingsList(rows: StandingsTable.rows(kind, in: snapshot, favorites: model.preferences.favorites))
        } else {
            ContentUnavailableView("No standings yet", systemImage: "list.number")
        }
    }
}

struct StandingsList: View {
    let rows: [StandingsRowModel]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(rows) { row in
                        StandingsRowView(row: row)
                            .id(row.id)
                    }
                }
            }
            .onAppear { scrollToFavorite(proxy) }
            .onChange(of: rows) { scrollToFavorite(proxy) }
        }
    }

    private func scrollToFavorite(_ proxy: ScrollViewProxy) {
        guard let target = StandingsTable.scrollTarget(in: rows) else { return }
        proxy.scrollTo(target, anchor: .center)
    }
}

struct StandingsRowView: View {
    let row: StandingsRowModel

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(row.isFavorite ? GridTheme.startRed : .clear)
                .frame(width: 4)
            Text("\(row.position)")
                .font(.body.monospacedDigit().weight(.semibold))
                .frame(minWidth: 24, alignment: .trailing)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.body.weight(row.isFavorite ? .bold : .regular))
                if let subtitle = row.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(GridTheme.muted)
                }
            }
            Spacer()
            Text(row.points)
                .font(.body.monospacedDigit().weight(row.isFavorite ? .bold : .regular))
        }
        .foregroundStyle(GridTheme.pitWhite)
        .padding(.vertical, 6)
        .padding(.trailing, 10)
        .background(row.isFavorite ? GridTheme.graphite : .clear, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
    }
}

struct ResultsHiddenCard: View {
    let weekendName: String
    let revealDate: Date?
    let onReveal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Results hidden", systemImage: "eye.slash")
                .font(.headline)
            Text("Spoiler-free is on for \(weekendName).")
                .font(.subheadline)
                .foregroundStyle(GridTheme.muted)
            if let revealDate {
                Text("Shows on its own \(revealDate, style: .relative) from now.")
                    .font(.caption)
                    .foregroundStyle(GridTheme.muted)
            }
            Button("Show results", action: onReveal)
                .buttonStyle(.borderedProminent)
                .tint(GridTheme.startRed)
        }
        .foregroundStyle(GridTheme.pitWhite)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(GridTheme.graphite, in: RoundedRectangle(cornerRadius: 14))
    }
}
