import GridWalkDesign
import GridWalkKit
import SwiftUI

/// The big "what's next" block: countdown, live badge, or off-season.
struct HeroCard: View {
    let state: HeroState

    var body: some View {
        switch state {
        case .upcoming(let timed):
            Card {
                header(timed, badge: Text("Up next"))
                CountdownText(to: timed.session.dateUTC, kind: timed.session.kind)
                footer(timed)
            }
        case .live(let timed):
            Card {
                header(timed, badge: nil)
                LiveBadge()
                footer(timed)
            }
        case .offSeason(let lastWeekend):
            StateView(
                .empty(systemImage: "moon.stars"),
                title: Text("Off-season"),
                message: offSeasonMessage(lastWeekend)
            )
        }
    }

    private func header(_ timed: TimedSession, badge: Text?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            SessionTag(timed.session.kind)
            Text(timed.session.kind.displayName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.text)
            Spacer(minLength: 4)
            if let badge {
                badge
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .textCase(.uppercase)
            }
        }
    }

    private func footer(_ timed: TimedSession) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(timed.weekend.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.text)
            Text(LocalTimeFormat.sessionDateTime(timed.session.dateUTC))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Theme.secondaryText)
        }
        .accessibilityElement(children: .combine)
    }

    private func offSeasonMessage(_ lastWeekend: RaceWeekend?) -> Text {
        if let lastWeekend {
            Text("The season ended with the \(lastWeekend.name). The new calendar shows up here once it's out.")
        } else {
            Text("The new calendar shows up here once it's out.")
        }
    }
}

private struct LiveBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Theme.accent)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
            Text("Live now")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.accent)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Upcoming") {
    HeroCard(state: WeekendTimeline.hero(races: SampleData.schedule(around: .now).races, at: .now))
        .padding()
        .screenBackground()
}

#Preview("Live") {
    // sample sprint starts 4h before the anchor, so this puts it 10 minutes in
    let races = SampleData.schedule(around: .now.addingTimeInterval(4 * 3600 - 600)).races
    HeroCard(state: WeekendTimeline.hero(races: races, at: .now))
        .padding()
        .screenBackground()
}

#Preview("Off-season") {
    let races = SampleData.schedule(around: .now, offSeason: true).races
    HeroCard(state: .offSeason(lastWeekend: races.last))
        .padding()
        .screenBackground()
}
