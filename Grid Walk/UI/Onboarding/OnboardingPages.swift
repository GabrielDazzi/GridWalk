import GridWalkDesign
import GridWalkKit
import SwiftUI

struct WelcomePage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to Grid Walk")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.text)
                Text("Every session of the race weekend, in your time zone.")
                    .font(.title3)
                    .foregroundStyle(Theme.secondaryText)
            }
            VStack(alignment: .leading, spacing: 16) {
                feature("timer", Text("A live countdown to the next session"))
                feature("bell", Text("Alerts 15 minutes before the ones you care about"))
                feature("eye.slash", Text("Spoiler-free mode until you've watched the race"))
                feature("lock", Text("Free, no account, no tracking"))
            }
        }
    }

    private func feature(_ symbol: String, _ text: Text) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            text
                .font(.body)
                .foregroundStyle(Theme.text)
        }
    }
}

/// Pick one driver or team, or none.
struct ChoicePage: View {
    let title: Text
    let choices: [FavoriteChoice]
    let status: FeedStatus
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            title
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.text)
            Text("They get highlighted in the standings. You can change this later in Settings.")
                .foregroundStyle(Theme.secondaryText)
            if choices.isEmpty {
                emptyState
            } else {
                Card {
                    VStack(spacing: 0) {
                        ForEach(choices) { choice in
                            row(choice)
                            if choice.id != choices.last?.id {
                                Divider().overlay(Theme.separator)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if status == .loading {
            StateView(.loading, title: Text("Loading drivers and teams"))
        } else {
            StateView(
                .empty(systemImage: "person.2"),
                title: Text("Nothing to pick yet"),
                message: Text("Standings aren't available right now. You can pick favorites later in Settings.")
            )
        }
    }

    private func row(_ choice: FavoriteChoice) -> some View {
        let isSelected = selection == choice.id
        return Button {
            selection = isSelected ? nil : choice.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(choice.title)
                        .font(.body.weight(isSelected ? .bold : .regular))
                        .foregroundStyle(Theme.text)
                    if let subtitle = choice.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.accent : Theme.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct MenuBarPage: View {
    @Binding var mode: MenuBarMode

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What should the menu bar show?")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.text)
            Text(
                "Auto shows the countdown on race weekends, the result right after a race, and your driver the rest of the time."
            )
            .foregroundStyle(Theme.secondaryText)
            Card {
                Picker("Menu bar", selection: $mode) {
                    ForEach(MenuBarMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
    }
}
