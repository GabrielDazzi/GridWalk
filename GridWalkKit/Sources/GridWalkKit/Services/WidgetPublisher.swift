import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

/// Hands the widget its data. The widget never touches the network.
public protocol WidgetPublishing: Sendable {
    func publish(_ snapshot: WidgetSnapshot?) async
}

/// Writes `widget_snapshot.json` into the App Group and reloads timelines.
public struct SharedWidgetPublisher: WidgetPublishing {
    public init() {}

    public func publish(_ snapshot: WidgetSnapshot?) async {
        try? WidgetSnapshotStore.save(snapshot)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
