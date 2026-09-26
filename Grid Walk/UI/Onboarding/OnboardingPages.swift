import GridWalkDesign
import GridWalkKit
import SwiftUI

struct WelcomePage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            #if os(macOS)
            BrandMark(size: 72)
            #endif
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
                    HStack(alignment: .top, spacing: 20) {
                        ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                            VStack(spacing: 0) {
                                ForEach(column) { choice in
                                    row(choice)
                                    if choice.id != column.last?.id {
                                        Divider().overlay(Theme.separator)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
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

    /// Two columns on the Mac window, one when the screen is narrow.
    private var columns: [[FavoriteChoice]] {
        guard horizontalSizeClass != .compact, choices.count > 1 else { return [choices] }
        let split = (choices.count + 1) / 2
        return [Array(choices.prefix(split)), Array(choices.dropFirst(split))]
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
                        .lineLimit(1)
                    if let subtitle = choice.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.accent : Theme.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 6)
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
