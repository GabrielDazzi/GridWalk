import Foundation

/// Why a feed request failed. `errorDescription` is safe to show to the user.
public enum FeedError: Error, Sendable, Equatable {
    case offline
    case timedOut
    case server(status: Int)
    case emptyResponse
    case malformedData
    case transport

    /// Maps whatever URLSession or the decoder threw into something the UI can explain.
    public init(_ error: any Error) {
        if let feedError = error as? FeedError {
            self = feedError
            return
        }
        if error is DecodingError {
            self = .malformedData
            return
        }
        guard let urlError = error as? URLError else {
            self = .transport
            return
        }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            self = .offline
        case .timedOut:
            self = .timedOut
        case .cannotDecodeContentData, .cannotParseResponse:
            self = .malformedData
        default:
            self = .transport
        }
    }
}

extension FeedError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .offline:
            "You're offline. Showing the last saved data."
        case .timedOut:
            "The data feed took too long to answer."
        case .server(let status):
            "The data feed is having trouble (error \(status))."
        case .emptyResponse:
            "The data feed returned nothing."
        case .malformedData:
            "The data feed sent something we couldn't read."
        case .transport:
            "Couldn't reach the data feed."
        }
    }
}
