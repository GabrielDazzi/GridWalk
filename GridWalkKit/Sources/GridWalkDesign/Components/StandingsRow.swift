import GridWalkKit
import SwiftUI

/// One line of a standings table. The favorite gets an accent bar and bold text, not just a color.
public struct StandingsRow: View {
    private let row: StandingsRowModel
    private let showsGap: Bool

    public init(_ row: StandingsRowModel, showsGap: Bool = true) {
        self.row = row
        self.showsGap = showsGap
    }

    public var body: some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(row.isFavorite ? Theme.accent : .clear)
                .frame(width: 4)
                .frame(maxHeight: .infinity)
            Text(row.position, format: .number)
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(row.isFavorite ? Theme.text : Theme.secondaryText)
                .frame(minWidth: 26, alignment: .trailing)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.body.weight(row.isFavorite ? .bold : .medium))
                    .foregroundStyle(Theme.text)
                if let subtitle = row.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(row.points)
                    .font(.body.monospacedDigit().weight(row.isFavorite ? .bold : .regular))
                    .foregroundStyle(Theme.text)
                if showsGap, let gap = row.gapToLeader {
                    Text(gap)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 8)
        .padding(.trailing, 12)
        .background {
            if row.isFavorite {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.card)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
    }
}

#Preview("Standings rows") {
    let rows = StandingsTable.driverRows(
        SampleData.standings(fetchedAt: .now).drivers,
        favorites: SampleData.favorites
    )
    return VStack(spacing: 2) {
        ForEach(rows) { StandingsRow($0) }
    }
    .padding()
    .screenBackground()
}
