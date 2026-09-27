import GridWalkDesign
import GridWalkKit
import SwiftUI

/// First-launch flow. Every step is optional; picks land in preferences right away.
struct OnboardingView: View {
    @Bindable var model: AppModel
    @State private var index: Int
    @Environment(\.dismiss) private var dismiss

    init(model: AppModel, initialStep: Int = 0) {
        self.model = model
        _index = State(initialValue: initialStep)
    }

    private var steps: [OnboardingStep] {
        #if os(macOS)
        OnboardingStep.steps(includesMenuBar: true)
        #else
        OnboardingStep.steps(includesMenuBar: false)
        #endif
    }

    private var step: OnboardingStep { steps[min(index, steps.count - 1)] }
    private var isLast: Bool { index >= steps.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            // window stays put, long pages scroll and the footer stays on the bottom edge
            ScrollView { pageFrame }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: .infinity)
            #else
            ViewThatFits(in: .vertical) {
                pageFrame
                ScrollView { pageFrame }
            }
            #endif
            controls
        }
        #if os(macOS)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
        .screenBackground()
        .tint(Theme.accent)
        .task { await model.start() }
    }

    private var pageFrame: some View {
        page
            .frame(maxWidth: 680, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var page: some View {
        switch step {
        case .welcome:
            WelcomePage()
        case .driver:
            ChoicePage(
                title: Text("Pick your driver"),
                choices: OnboardingChoices.drivers(in: model.standings.snapshot),
                status: model.standings.status,
                selection: $model.preferences.favorites.driverCode
            )
        case .team:
            ChoicePage(
                title: Text("Pick your team"),
                choices: OnboardingChoices.teams(in: model.standings.snapshot),
                status: model.standings.status,
                selection: $model.preferences.favorites.constructorId
            )
        case .menuBar:
            MenuBarPage(mode: $model.preferences.menuBar.mode)
        case .notifications:
            AlertsPage(model: model)
        }
    }

    private var controls: some View {
        HStack {
            if index > 0 {
                Button("Back") { index -= 1 }
                    .buttonStyle(.borderless)
            }
            Spacer()
            Text("Step \(index + 1) of \(steps.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.secondaryText)
            Spacer()
            Button {
                if isLast {
                    finish()
                } else {
                    index += 1
                }
            } label: {
                Text(isLast ? "Done" : "Next")
                    .frame(minWidth: 80)
            }
            .buttonStyle(.primary)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Theme.card)
    }

    private func finish() {
        model.preferences.hasFinishedOnboarding = true
        dismiss()
    }
}

#Preview("Onboarding") {
    OnboardingView(model: .preview(.firstLaunch))
}

#Preview("Onboarding, driver") {
    OnboardingView(model: .preview(.firstLaunch), initialStep: 1)
}

#Preview("Onboarding, offline") {
    OnboardingView(model: .preview(.failed))
}
