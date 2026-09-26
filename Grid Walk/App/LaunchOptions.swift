import GridWalkKit
import SwiftUI

extension AppModel {
    /// Live services, or sample data when a debug build is launched with `-demo <scenario>`.
    static func forLaunch() -> AppModel {
        #if DEBUG
        if let scenario = LaunchOptions.demoScenario {
            return .preview(scenario)
        }
        #endif
        return .live()
    }
}

// debug-only switches for screenshots, e.g. `-demo resultsHidden -tab standings`
enum LaunchOptions {
    static var demoScenario: PreviewScenario? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "demo").flatMap(PreviewScenario.init(rawValue:))
        #else
        nil
        #endif
    }

    static var initialTab: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "tab")
        #else
        nil
        #endif
    }
}
