import GridWalkKit
import SwiftUI
import WidgetKit

@main
struct GridWalkWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextSessionWidget()
        #if os(iOS)
        SessionLiveActivityWidget()
        #endif
    }
}
