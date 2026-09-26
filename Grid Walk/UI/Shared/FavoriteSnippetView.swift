import GridWalkDesign
import GridWalkKit
import SwiftUI

/// Favorite driver and team positions, or why they aren't shown.
struct FavoriteSnippetView: View {
    let snippet: FavoriteSnippet
    let onReveal: () -> Void
    let onPick: () -> Void

    var body: some View {
        switch snippet {
        case .hidden(let weekend, let revealDate):
            ResultsHiddenCard(weekendName: weekend.name, revealDate: revealDate, onReveal: onReveal)
        case .rows(let rows):
            Card(Text("Your favorites")) {
                VStack(spacing: 2) {
                    ForEach(rows) { StandingsRow($0) }
                }
            }
        case .pickFavorites:
            Card(Text("Your favorites")) {
                Text("Pick a driver and a team to see where they stand.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                Button("Pick favorites", action: onPick)
                    .buttonStyle(.secondary)
            }
        case .unavailable:
            Card(Text("Your favorites")) {
                Text("Standings show up after the first race.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}

#Preview("Favorites") {
    let snapshot = SampleData.standings(fetchedAt: .now)
    ScrollView {
        VStack(spacing: 16) {
            FavoriteSnippetView(
                snippet: .make(snapshot: snapshot, favorites: SampleData.favorites, spoilers: .visible),
                onReveal: {},
                onPick: {}
            )
            FavoriteSnippetView(snippet: .pickFavorites, onReveal: {}, onPick: {})
            FavoriteSnippetView(snippet: .unavailable, onReveal: {}, onPick: {})
        }
        .padding()
    }
    .screenBackground()
}

#Preview("Spoiler hidden") {
    let weekend = SampleData.schedule(around: .now).races[2]
    FavoriteSnippetView(
        snippet: .hidden(weekend: weekend, revealDate: .now.addingTimeInterval(160_000)),
        onReveal: {},
        onPick: {}
    )
    .padding()
    .screenBackground()
}
