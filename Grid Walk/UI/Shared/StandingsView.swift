import GridWalkDesign
import GridWalkKit
import SwiftUI

/// Drivers and teams tables. Opens scrolled to the favorite; hidden while spoiler-free is on.
struct StandingsView: View {
    let model: AppModel
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
                .padding(.horizontal)

                content(now: context.date)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .padding(.top, 8)
        }
        .screenBackground()
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let spoilers = model.spoilerState(at: now)
        let status = model.standings.status
        if let weekend = spoilers.hiddenWeekend {
            ResultsHiddenCard(weekendName: weekend.name, revealDate: spoilers.revealDate) {
                model.revealResults(at: now)
            }
            .padding(.horizontal)
        } else if let snapshot = model.standings.snapshot {
            let rows = StandingsTable.rows(kind, in: snapshot, favorites: model.preferences.favorites)
            if rows.isEmpty {
                StateView(
                    .empty(systemImage: "list.number"),
                    title: Text("No standings yet"),
                    message: Text("They show up after the first race of the season.")
                )
                .padding(.horizontal)
            } else {
                StandingsList(rows: rows, status: status)
            }
        } else if case .failed(let error) = status {
            StateView.failed(error, title: Text("Couldn't load standings")) {
                Task { await model.refreshNow() }
            }
            .padding(.horizontal)
        } else {
            StateView(.loading, title: Text("Loading standings"))
                .padding(.horizontal)
        }
    }
}

private struct StandingsList: View {
    let rows: [StandingsRowModel]
    let status: FeedStatus

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(rows) { row in
                        StandingsRow(row).id(row.id)
                    }
                    FreshnessLabel(status)
                        .padding(.top, 12)
                }
                .padding(.horizontal)
                .padding(.bottom)
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

#Preview("Standings") {
    let model = AppModel.preview()
    StandingsView(model: model).task { await model.start() }
}

#Preview("Spoiler hidden") {
    let model = AppModel.preview(.resultsHidden)
    StandingsView(model: model).task { await model.start() }
}

#Preview("Loading") {
    let model = AppModel.preview(.loading)
    StandingsView(model: model).task { await model.start() }
}

#Preview("Error") {
    let model = AppModel.preview(.failed)
    StandingsView(model: model).task { await model.start() }
}
