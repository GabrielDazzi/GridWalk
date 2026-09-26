#if DEBUG && os(macOS)
import AppKit
import GridWalkDesign
import GridWalkKit
import SwiftUI

// `-snapshots <dir>` renders the popover and onboarding with sample data to PNGs and quits, for README art.
// Runs from App.init before any scene exists. ImageRenderer can't draw AppKit-backed controls
// (scroll views, forms, switches) or Liquid Glass, so cards use the solid fallback and only screens
// without those controls are exported here.
@MainActor
enum MacSnapshots {
    static func exportIfRequested() {
        guard let path = UserDefaults.standard.string(forKey: "snapshots") else { return }
        let directory = URL(filePath: path)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let panels: [(PreviewScenario, String)] = [
            (.raceWeekend, "popover"),
            (.resultsHidden, "popover-spoiler-hidden"),
            (.offline, "popover-offline"),
            (.loading, "popover-loading"),
            (.failed, "popover-error"),
            (.offSeason, "popover-off-season"),
        ]
        for (suffix, name) in [("dark", NSAppearance.Name.darkAqua), ("light", .aqua)] {
            guard let appearance = NSAppearance(named: name) else { continue }
            let scheme: ColorScheme = name == .darkAqua ? .dark : .light
            func save(_ view: some View, _ file: String) {
                appearance.performAsCurrentDrawingAppearance {
                    let renderer = ImageRenderer(
                        content: view.environment(\.colorScheme, scheme).environment(\.prefersSolidSurfaces, true)
                    )
                    renderer.scale = 2
                    guard let image = renderer.cgImage else { return }
                    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
                    try? data?.write(to: directory.appending(path: "\(file)-\(suffix).png"))
                }
            }
            for (scenario, file) in panels {
                save(MenuBarPanel(model: loaded(scenario)), file)
            }
            let fresh = loaded(.firstLaunch)
            save(onboardingPage(WelcomePage()), "onboarding-welcome")
            save(
                onboardingPage(
                    ChoicePage(
                        title: Text("Pick your driver"),
                        choices: OnboardingChoices.drivers(in: fresh.standings.snapshot),
                        status: fresh.standings.status,
                        selection: .constant("OKA")
                    )
                ),
                "onboarding-driver"
            )
        }
        exit(0)
    }

    private static func onboardingPage(_ page: some View) -> some View {
        page
            .padding(24)
            .frame(width: 560, alignment: .leading)
            .screenBackground()
    }

    // the loading scenario never finishes starting, so it only gets a short head start
    private static func loaded(_ scenario: PreviewScenario) -> AppModel {
        let model = AppModel.preview(scenario)
        var started = false
        Task {
            await model.start()
            started = true
        }
        let deadline = Date().addingTimeInterval(scenario == .loading ? 0.3 : 3)
        while !started, Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        return model
    }
}
#endif
