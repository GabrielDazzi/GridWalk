import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

public enum WidgetReload {
    public static func reloadAll() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
