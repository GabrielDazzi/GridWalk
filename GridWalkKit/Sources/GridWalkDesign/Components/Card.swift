import SwiftUI

/// Rounded block that groups one piece of content, with an optional small caps title.
public struct Card<Content: View>: View {
    private let title: Text?
    private let content: Content

    public init(_ title: Text? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                title
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

#Preview("Card") {
    VStack(spacing: 16) {
        Card(Text(verbatim: "Up next")) {
            Text(verbatim: "Qualifying").font(.title2.bold()).foregroundStyle(Theme.text)
        }
        Card {
            Text(verbatim: "No title").foregroundStyle(Theme.text)
        }
    }
    .padding()
    .screenBackground()
}
