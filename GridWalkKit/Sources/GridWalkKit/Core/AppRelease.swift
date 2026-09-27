import Foundation

/// `1.2.0` or `v1.2.0-beta.1`. A release build sorts above any prerelease of the same numbers.
public struct SemanticVersion: Comparable, Sendable, Equatable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: [String]

    public init?(_ raw: String) {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.first?.lowercased() == "v" { text.removeFirst() }
        let split = text.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let numbers = split[0].split(separator: ".")
        guard (1...3).contains(numbers.count) else { return nil }
        guard let major = Int(numbers[0]), major >= 0 else { return nil }
        let minor = numbers.count > 1 ? Int(numbers[1]) : 0
        let patch = numbers.count > 2 ? Int(numbers[2]) : 0
        guard let minor, minor >= 0, let patch, patch >= 0 else { return nil }
        self.major = major
        self.minor = minor
        self.patch = patch
        if split.count == 2, !split[1].isEmpty {
            prerelease = split[1].split(separator: ".").map(String.init)
        } else {
            prerelease = []
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if (lhs.major, lhs.minor, lhs.patch) != (rhs.major, rhs.minor, rhs.patch) {
            return (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
        }
        if lhs.prerelease.isEmpty { return false }
        if rhs.prerelease.isEmpty { return true }
        let limit = min(lhs.prerelease.count, rhs.prerelease.count)
        for index in 0..<limit {
            let order = compareIdentifier(lhs.prerelease[index], rhs.prerelease[index])
            if order != 0 { return order < 0 }
        }
        return lhs.prerelease.count < rhs.prerelease.count
    }

    // numeric identifiers sort before words, and as numbers
    private static func compareIdentifier(_ lhs: String, _ rhs: String) -> Int {
        switch (Int(lhs), Int(rhs)) {
        case (let left?, let right?) where left != right:
            return left < right ? -1 : 1
        case (let left?, let right?) where left == right:
            return 0
        case (.some, .none):
            return -1
        case (.none, .some):
            return 1
        default:
            if lhs == rhs { return 0 }
            return lhs < rhs ? -1 : 1
        }
    }
}

/// A GitHub release that shipped a disk image newer than the running app.
public struct AppRelease: Sendable, Equatable {
    public let tag: String
    public let version: SemanticVersion
    public let diskImageURL: URL
    public let byteCount: Int64?

    public init(tag: String, version: SemanticVersion, diskImageURL: URL, byteCount: Int64?) {
        self.tag = tag
        self.version = version
        self.diskImageURL = diskImageURL
        self.byteCount = byteCount
    }
}

/// Reads the public GitHub "latest release" payload. No network of its own.
public enum ReleaseLookup {
    public static let repository = "GabrielDazzi/GridWalk"

    public static func latestURL() -> URL? {
        URL(string: "https://api.github.com/repos/\(repository)/releases/latest")
    }

    /// The disk image to install, or nil when this copy is already current.
    public static func newerRelease(current: String, json: Data) throws -> AppRelease? {
        let payload = try JSONDecoder().decode(Payload.self, from: json)
        guard !payload.draft, !payload.prerelease else { return nil }
        guard let latest = SemanticVersion(payload.tagName), let running = SemanticVersion(current) else {
            throw LookupError.unreadableVersion
        }
        guard running < latest else { return nil }
        guard let asset = payload.assets.first(where: { $0.name.lowercased().hasSuffix(".dmg") }) else {
            return nil
        }
        guard let url = URL(string: asset.browserDownloadURL), allowsDownload(from: url) else {
            throw LookupError.untrustedDownload
        }
        return AppRelease(
            tag: payload.tagName,
            version: latest,
            diskImageURL: url,
            byteCount: asset.size
        )
    }

    /// The link named in the release JSON. Has to be this repo, not any file on those hosts.
    public static func allowsDownload(from url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else { return false }
        if host == "github.com" { return isRepoDiskImage(url) }
        if host == "api.github.com" { return isRepoReleaseAPI(url) }
        return false
    }

    /// GitHub answers that download with a redirect onto its own files host.
    public static func allowsDownloadRedirect(from url: URL) -> Bool {
        if allowsDownload(from: url) { return true }
        guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else { return false }
        if host == "objects.githubusercontent.com" { return true }
        return host.hasSuffix(".githubusercontent.com")
    }

    private static func isRepoDiskImage(_ url: URL) -> Bool {
        guard let parts = pathParts(url), parts.count >= 6 else { return false }
        guard let (owner, name) = ownerAndName else { return false }
        guard parts[0] == owner, parts[1] == name, parts[2] == "releases", parts[3] == "download" else {
            return false
        }
        return parts.last?.lowercased().hasSuffix(".dmg") == true
    }

    private static func isRepoReleaseAPI(_ url: URL) -> Bool {
        guard let parts = pathParts(url), parts.count >= 5 else { return false }
        guard let (owner, name) = ownerAndName else { return false }
        return parts[0] == "repos" && parts[1] == owner && parts[2] == name && parts[3] == "releases"
    }

    private static var ownerAndName: (String, String)? {
        let parts = repository.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        return (parts[0], parts[1])
    }

    private static func pathParts(_ url: URL) -> [String]? {
        let parts = url.path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        if parts.contains(".") || parts.contains("..") { return nil }
        return parts
    }
}

public enum LookupError: Error, Equatable {
    case unreadableVersion
    case untrustedDownload
}

private struct Payload: Decodable {
    let tagName: String
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case draft
        case prerelease
        case assets
    }
}

private struct Asset: Decodable {
    let name: String
    let browserDownloadURL: String
    let size: Int64?

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case size
    }
}
