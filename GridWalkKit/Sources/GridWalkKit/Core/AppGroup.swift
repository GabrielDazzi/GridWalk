import Foundation

public enum AppGroup {
    public static let identifier = "group.com.gabrieldazzi.gridwalk"

    /// Shared container used by the app and widget.
    public static func containerURL(fileManager: FileManager = .default) -> URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    /// Prefers the App Group; falls back to Application Support if the group is missing or not writable.
    public static func cacheDirectory(fileManager: FileManager = .default) throws -> URL {
        if let group = containerURL(fileManager: fileManager) {
            let folder = group.appendingPathComponent("Library/Caches/GridWalk", isDirectory: true)
            do {
                try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
                return folder
            } catch {
                // Group URL can exist without write access (e.g. `swift test` without entitlements).
            }
        }

        let support = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = support.appendingPathComponent("GridWalk", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}
