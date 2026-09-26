import SwiftUI

/// Shown wherever results would be while spoiler-free is hiding a weekend. One tap reveals everything.
public struct ResultsHiddenCard: View {
    private let weekendName: String
    private let revealDate: Date?
    private let onReveal: () -> Void

    public init(weekendName: String, revealDate: Date?, onReveal: @escaping () -> Void) {
        self.weekendName = weekendName
        self.revealDate = revealDate
        self.onReveal = onReveal
    }

    public var body: some View {
        Card {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "eye.slash.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Results hidden", bundle: .module)
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    Text("Spoiler-free is on for \(weekendName).", bundle: .module)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                    if let revealDate {
                        Text(
                            "Shows on its own \(revealDate, format: .relative(presentation: .named)).", bundle: .module
                        )
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            Button(action: onReveal) {
                Text("Show results", bundle: .module)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
        }
    }
}

#Preview("Results hidden") {
    ResultsHiddenCard(weekendName: "Lakeside Grand Prix", revealDate: .now.addingTimeInterval(160_000)) {}
        .padding()
        .screenBackground()
}
