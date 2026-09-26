import Foundation

/// Why reading or writing the on-device cache failed.
public enum CacheError: Error, Sendable, Equatable {
    case unavailable
    case unreadable
    case unwritable
}

/// Keeps the last good copy of a feed value so the app works offline.
public protocol Caching<Value>: Sendable {
    associatedtype Value: Codable & Sendable

    func load() async throws(CacheError) -> Value?
    func save(_ value: Value) async throws(CacheError)
}

/// JSON file cache. Lives in the App Group container so the widget can read it too.
public actor FileCache<Value: Codable & Sendable>: Caching {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// A cache file in the shared container, falling back to Application Support.
    public static func shared(fileName: String) throws(CacheError) -> FileCache<Value> {
        do {
            let folder = try AppGroup.cacheDirectory()
            return FileCache(fileURL: folder.appendingPathComponent(fileName))
        } catch {
            throw .unavailable
        }
    }

    public func load() throws(CacheError) -> Value? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try Self.decoder.decode(Value.self, from: data)
        } catch {
            throw .unreadable
        }
    }

    public func save(_ value: Value) throws(CacheError) {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Self.encoder.encode(value).write(to: fileURL, options: .atomic)
        } catch {
            throw .unwritable
        }
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

/// In-memory cache for tests, previews, and when the disk isn't available.
public actor MemoryCache<Value: Codable & Sendable>: Caching {
    private var stored: Value?

    public init(_ value: Value? = nil) {
        stored = value
    }

    public func load() -> Value? {
        stored
    }

    public func save(_ value: Value) {
        stored = value
    }
}
