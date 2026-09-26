import GridWalkKit
import SwiftUI

/// Colored capsule for a session. Always carries text (FP, Q, S, R plus the short name), never color alone.
public struct SessionTag: View {
    public enum Size: Sendable {
        /// Letters only, for dense rows.
        case compact
        /// Letters and short name.
        case regular
    }

    private let kind: SessionKind
    private let size: Size

    public init(_ kind: SessionKind, size: Size = .regular) {
        self.kind = kind
        self.size = size
    }

    public var body: some View {
        let category = kind.alertCategory
        HStack(spacing: 4) {
            Text(category.tagLetters)
                .fontWeight(.heavy)
            if size == .regular, kind.shortName != category.tagLetters {
                Text(kind.shortName)
                    .fontWeight(.semibold)
            }
        }
        .font(.caption2.monospacedDigit())
        .lineLimit(1)
        .foregroundStyle(Theme.tagLabel(for: category))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Theme.tagFill(for: category), in: Capsule())
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(kind.displayName)
    }
}

#Preview("Session tags") {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            ForEach(SessionKind.allCases, id: \.self) { SessionTag($0, size: .compact) }
        }
        ForEach(SessionKind.allCases, id: \.self) { SessionTag($0) }
    }
    .padding()
    .screenBackground()
}
