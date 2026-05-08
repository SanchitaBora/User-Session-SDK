import Foundation

/// Collects raw events from the host app, enriches them, and forwards to store and graph.
public final class EventCollector: @unchecked Sendable {
    private let store: LocalEventStore
    private let graphBuilder: SessionGraphBuilder
    private let config: SessionSDKConfiguration
    private let sessionIdProvider: () -> String
    private var currentSessionId: String?

    public init(
        store: LocalEventStore,
        graphBuilder: SessionGraphBuilder,
        config: SessionSDKConfiguration,
        sessionIdProvider: @escaping () -> String = { UUID().uuidString }
    ) {
        self.store = store
        self.graphBuilder = graphBuilder
        self.config = config
        self.sessionIdProvider = sessionIdProvider
    }

    /// Track an event. Enriches with timestamp, sessionId, tenantId and forwards to store and graph.
    public func track(_ event: SessionEvent) {
        let sessionId: String
        switch event {
        case .sessionStart:
            sessionId = sessionIdProvider()
            currentSessionId = sessionId
        case .sessionEnd:
            sessionId = currentSessionId ?? sessionIdProvider()
        default:
            sessionId = currentSessionId ?? sessionIdProvider()
            if currentSessionId == nil {
                currentSessionId = sessionId
            }
        }

        let enriched = EnrichedEvent(
            event: event,
            timestamp: Date(),
            sessionId: sessionId,
            tenantId: config.tenantId
        )
        store.append(enriched)
        graphBuilder.process(enriched)
    }
}
