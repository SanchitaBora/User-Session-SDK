import Foundation

/// Node in the session graph (screen or product).
public enum GraphNode: Hashable, Sendable {
    case screen(String)
    case product(String)
    case screenProduct(screenId: String, productId: String)
    case action(String)
}

/// Edge between two nodes with transition metadata.
public struct GraphEdge: Sendable {
    public var transitionCount: Int
    public var totalDwellBefore: TimeInterval
    public var lastTimestamp: Date?

    public var avgDwellBefore: TimeInterval {
        guard transitionCount > 0 else { return 0 }
        return totalDwellBefore / Double(transitionCount)
    }

    public init(transitionCount: Int = 1, totalDwellBefore: TimeInterval = 0, lastTimestamp: Date? = nil) {
        self.transitionCount = transitionCount
        self.totalDwellBefore = totalDwellBefore
        self.lastTimestamp = lastTimestamp
    }

    public mutating func addTransition(dwellBefore: TimeInterval = 0) {
        transitionCount += 1
        totalDwellBefore += dwellBefore
        lastTimestamp = Date()
    }
}

/// Snapshot of the current session graph (nodes and edges).
public struct SessionGraphSnapshot: Sendable {
    public var nodes: Set<GraphNode>
    public var edges: [GraphNode: [GraphNode: GraphEdge]]
    public var nodeMetadata: [GraphNode: NodeMetadata]
    public var lastScreenNode: GraphNode?
    public var recentScreenSequence: [GraphNode]
    public var recentProductSequence: [GraphNode]
    /// Dwell accumulated on current node (reset on transition).
    public var currentDwellStart: Date?

    public init(
        nodes: Set<GraphNode> = [],
        edges: [GraphNode: [GraphNode: GraphEdge]] = [:],
        nodeMetadata: [GraphNode: NodeMetadata] = [:],
        lastScreenNode: GraphNode? = nil,
        recentScreenSequence: [GraphNode] = [],
        recentProductSequence: [GraphNode] = [],
        currentDwellStart: Date? = nil
    ) {
        self.nodes = nodes
        self.edges = edges
        self.nodeMetadata = nodeMetadata
        self.lastScreenNode = lastScreenNode
        self.recentScreenSequence = recentScreenSequence
        self.recentProductSequence = recentProductSequence
        self.currentDwellStart = currentDwellStart
    }
}

public struct NodeMetadata: Sendable {
    public var longDwellCount: Int
    public var totalVisitCount: Int
    public var lastVisitDate: Date?
    public var label: String?
    public var kind: String?
    public var targetId: String?
    public var metadata: [String: String]?

    public init(
        longDwellCount: Int = 0,
        totalVisitCount: Int = 0,
        lastVisitDate: Date? = nil,
        label: String? = nil,
        kind: String? = nil,
        targetId: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.longDwellCount = longDwellCount
        self.totalVisitCount = totalVisitCount
        self.lastVisitDate = lastVisitDate
        self.label = label
        self.kind = kind
        self.targetId = targetId
        self.metadata = metadata
    }
}
