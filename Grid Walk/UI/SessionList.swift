import SwiftUI
import GridWalkKit

struct SessionList: View {
    let weekend: RaceWeekend
    let nextSessionID: String?
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(weekend.sessions) { session in
                let isNext = session.id == nextSessionID
                HStack(spacing: 10) {
                    SessionTagChip(kind: session.kind)

                    Text(session.kind.displayName)
                        .font(.subheadline.weight(isNext ? .semibold : .regular))
                        .foregroundStyle(GridTheme.pitWhite)

                    Spacer(minLength: 8)

                    Text(LocalTimeFormat.sessionDateTime(session.dateUTC))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(isNext ? GridTheme.pitWhite : GridTheme.muted)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    isNext ? GridTheme.startRed.opacity(0.14) : GridTheme.graphite,
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isNext ? GridTheme.startRed.opacity(0.45) : Color.clear, lineWidth: 1)
                )
            }
        }
    }
}
