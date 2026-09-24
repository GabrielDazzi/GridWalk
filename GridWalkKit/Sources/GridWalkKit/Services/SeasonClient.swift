import Foundation

public enum SeasonFetchError: Error, Sendable {
    case badStatus(Int)
    case emptyBody
}

public protocol SeasonFetching: Sendable {
    func fetchCurrentSeason() async throws -> Data
}

public struct SeasonClient: SeasonFetching {
    public static let endpoint = URL(string: "https://api.jolpi.ca/ergast/f1/current.json?limit=100")!

    private let session: URLSession
    private let url: URL

    public init(session: URLSession = .shared, url: URL = SeasonClient.endpoint) {
        self.session = session
        self.url = url
    }

    public func fetchCurrentSeason() async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SeasonFetchError.badStatus(http.statusCode)
        }
        guard !data.isEmpty else { throw SeasonFetchError.emptyBody }
        return data
    }
}
