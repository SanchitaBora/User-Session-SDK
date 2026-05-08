import Foundation

/// Session event types reported by the host app.
public enum SessionEvent {
    case sessionStart
    case sessionEnd
    case screenView(screenId: String, context: [String: String]?)
    case scroll(screenId: String, direction: ScrollDirection, position: Double?)
    case back(screenId: String, fromScreenId: String?)
    case dwell(screenId: String, duration: TimeInterval)
    case productView(productId: String, screenId: String?)
    case productInterest(productId: String, action: String?)
    case action(screenId: String, kind: ActionKind, name: String, targetId: String?, metadata: [String: String]?)
    case gesture(screenId: String, kind: GestureKind, name: String?, metadata: [String: String]?)
}

public enum ScrollDirection: String, Codable, Sendable {
    case up
    case down
    case left
    case right
}

public enum ActionKind: String, Codable, Sendable {
    case tap
    case valueChange
    case submit
    case select
    case open
    case custom
}

public enum GestureKind: String, Codable, Sendable {
    case swipe
    case pan
    case longPress
    case custom
}

/// Internal enriched event with timestamp and session id.
public struct EnrichedEvent: Sendable {
    public let event: SessionEvent
    public let timestamp: Date
    public let sessionId: String
    public let tenantId: String

    public init(event: SessionEvent, timestamp: Date, sessionId: String, tenantId: String) {
        self.event = event
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.tenantId = tenantId
    }
}
