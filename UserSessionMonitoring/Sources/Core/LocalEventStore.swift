import Foundation

/// In-memory store of recent enriched events (no persistence in base implementation).
public final class LocalEventStore: @unchecked Sendable {
    public static let defaultMaxEvents = 500

    private let maxEvents: Int
    private let lock = NSLock()
    private var events: [EnrichedEvent] = []

    public init(maxEvents: Int = defaultMaxEvents) {
        self.maxEvents = maxEvents
    }

    public func append(_ event: EnrichedEvent) {
        lock.lock()
        events.append(event)
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
        lock.unlock()
    }

    /// Recent events (e.g. for feature extraction or cloud upload). Newest last.
    public func recentEvents(limit: Int = 100) -> [EnrichedEvent] {
        lock.lock()
        let slice = Array(events.suffix(limit))
        lock.unlock()
        return slice
    }

    /// All events in store (newest last).
    public func allEvents() -> [EnrichedEvent] {
        lock.lock()
        let copy = events
        lock.unlock()
        return copy
    }

    public func clear() {
        lock.lock()
        events.removeAll()
        lock.unlock()
    }
}
