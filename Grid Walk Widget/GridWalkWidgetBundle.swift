import WidgetKit
import SwiftUI
import GridWalkKit

@main
struct GridWalkWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextSessionWidget()
        #if os(iOS)
        SessionLiveActivityWidget()
        #endif
    }
}
