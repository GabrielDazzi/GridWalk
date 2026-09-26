import Foundation

/// Where "now" comes from, so tests can move time around.
public protocol TimeSource: Sendable {
    var now: Date { get }
}

/// The real wall clock.
public struct SystemTimeSource: TimeSource {
    public init() {}

    public var now: Date { .now }
}
