import Foundation

/// The four Jolpica documents the app reads.
public enum FeedEndpoint: Sendable, CaseIterable, Hashable {
    case schedule
    case driverStandings
    case constructorStandings
    case lastResults

    var address: String {
        switch self {
        case .schedule: "https://api.jolpi.ca/ergast/f1/current.json?limit=100"
        case .driverStandings: "https://api.jolpi.ca/ergast/f1/current/driverStandings.json"
        case .constructorStandings: "https://api.jolpi.ca/ergast/f1/current/constructorStandings.json"
        case .lastResults: "https://api.jolpi.ca/ergast/f1/current/last/results.json"
        }
    }
}

/// Raw access to the data feed. Swap in a fake in tests and previews.
public protocol FeedFetching: Sendable {
    func data(for endpoint: FeedEndpoint) async throws(FeedError) -> Data
}

/// Live Jolpica client. Only talks to api.jolpi.ca.
public struct JolpicaClient: FeedFetching {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for endpoint: FeedEndpoint) async throws(FeedError) -> Data {
        guard let url = URL(string: endpoint.address) else { throw .transport }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw FeedError(error)
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw .server(status: http.statusCode)
        }
        guard !data.isEmpty else { throw .emptyResponse }
        return data
    }
}
