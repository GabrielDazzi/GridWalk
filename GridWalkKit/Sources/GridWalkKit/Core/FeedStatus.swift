import Foundation

/// What a screen should show for one feed: a spinner, the data, the data with a warning, or an error.
public enum FeedStatus: Sendable, Equatable {
    /// Nothing cached yet and no failure to report.
    case loading
    /// Data is current.
    case ready(lastUpdated: Date)
    /// Showing cached data because the last refresh failed.
    case stale(lastUpdated: Date, error: FeedError)
    /// Nothing to show and the refresh failed.
    case failed(FeedError)

    public init(lastUpdated: Date?, error: FeedError?, isRefreshing: Bool) {
        switch (lastUpdated, error) {
        case (let date?, nil): self = .ready(lastUpdated: date)
        case (let date?, let error?): self = .stale(lastUpdated: date, error: error)
        case (nil, let error?) where !isRefreshing: self = .failed(error)
        case (nil, _): self = .loading
        }
    }

    public var lastUpdated: Date? {
        switch self {
        case .ready(let date), .stale(let date, _): date
        case .loading, .failed: nil
        }
    }

    public var error: FeedError? {
        switch self {
        case .stale(_, let error), .failed(let error): error
        case .loading, .ready: nil
        }
    }

    public var isOffline: Bool { error == .offline }
}

extension ScheduleStore {
    public var status: FeedStatus {
        FeedStatus(lastUpdated: lastUpdated, error: lastError, isRefreshing: isRefreshing)
    }
}

extension StandingsStore {
    public var status: FeedStatus {
        FeedStatus(lastUpdated: snapshot?.fetchedAt, error: lastError, isRefreshing: isRefreshing)
    }
}
