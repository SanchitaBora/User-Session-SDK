import Foundation

/// Builds and maintains the in-memory session graph from enriched events.
public final class SessionGraphBuilder: @unchecked Sendable {
    public static let defaultRecentCapacity = 20
    public static let defaultLongDwellThreshold: TimeInterval = 30

    private let recentCapacity: Int
    private let longDwellThreshold: TimeInterval
    private let lock = NSLock()
    private var snapshot = SessionGraphSnapshot()
    private var lastDwellStart: Date?
    private var lastScreenBeforeDwell: GraphNode?

    public init(recentCapacity: Int = defaultRecentCapacity, longDwellThreshold: TimeInterval = defaultLongDwellThreshold) {
        self.recentCapacity = recentCapacity
        self.longDwellThreshold = longDwellThreshold
    }

    /// Process an enriched event and update the graph.
    public func process(_ enriched: EnrichedEvent) {
        lock.lock()
        defer { lock.unlock() }

        switch enriched.event {
        case .sessionStart:
            snapshot.lastScreenNode = nil
            snapshot.recentScreenSequence.removeAll()
            snapshot.recentProductSequence.removeAll()
            snapshot.currentDwellStart = nil
            lastDwellStart = nil
            lastScreenBeforeDwell = nil

        case .sessionEnd:
            snapshot.currentDwellStart = nil
            lastDwellStart = nil

        case .screenView(let screenId, _):
            let node = GraphNode.screen(screenId)
            addNode(node)
            if let from = snapshot.lastScreenNode {
                addEdge(from: from, to: node, dwellBefore: computeDwellBefore(enriched.timestamp))
                appendRecentScreen(node)
            } else {
                appendRecentScreen(node)
            }
            snapshot.lastScreenNode = node
            snapshot.currentDwellStart = enriched.timestamp
            lastDwellStart = enriched.timestamp
            lastScreenBeforeDwell = node
            updateNodeMetadata(node, visit: true, longDwell: false)

        case .scroll:
            break

        case .back(let screenId, let fromScreenId):
            let toNode = GraphNode.screen(screenId)
            let fromNode: GraphNode = (fromScreenId.map { GraphNode.screen($0) }) ?? (snapshot.lastScreenNode ?? toNode)
            addNode(toNode)
            addNode(fromNode)
            addEdge(from: fromNode, to: toNode, dwellBefore: computeDwellBefore(enriched.timestamp))
            appendRecentScreen(toNode)
            snapshot.lastScreenNode = toNode
            snapshot.currentDwellStart = enriched.timestamp
            lastDwellStart = enriched.timestamp
            lastScreenBeforeDwell = toNode
            updateNodeMetadata(toNode, visit: true, longDwell: false)

        case .dwell(let screenId, let duration):
            let node = GraphNode.screen(screenId)
            addNode(node)
            if duration >= longDwellThreshold {
                updateNodeMetadata(node, visit: false, longDwell: true)
            }
            snapshot.currentDwellStart = enriched.timestamp

        case .productView(let productId, let screenId):
            let screenNode = screenId.map { GraphNode.screen($0) } ?? snapshot.lastScreenNode
            let productNode = GraphNode.product(productId)
            let composite = GraphNode.screenProduct(screenId: screenId ?? "", productId: productId)
            addNode(productNode)
            addNode(composite)
            if let screen = screenNode {
                addNode(screen)
                addEdge(from: screen, to: productNode, dwellBefore: 0)
            }
            appendRecentProduct(productNode)
            updateNodeMetadata(productNode, visit: true, longDwell: false)

        case .productInterest:
            break

        case .action(let screenId, let kind, let name, let targetId, let metadata):
            let screenNode = GraphNode.screen(screenId)
            let actionNode = GraphNode.action("action:\(kind.rawValue):\(name)")
            addNode(screenNode)
            addNode(actionNode)
            addEdge(from: screenNode, to: actionNode, dwellBefore: computeDwellBefore(enriched.timestamp))
            setNodeMetadata(actionNode, label: name, kind: kind.rawValue, targetId: targetId, metadata: metadata)

        case .gesture(let screenId, let kind, let name, let metadata):
            let screenNode = GraphNode.screen(screenId)
            let actionName = name ?? kind.rawValue
            let actionNode = GraphNode.action("gesture:\(kind.rawValue):\(actionName)")
            addNode(screenNode)
            addNode(actionNode)
            addEdge(from: screenNode, to: actionNode, dwellBefore: computeDwellBefore(enriched.timestamp))
            setNodeMetadata(actionNode, label: actionName, kind: kind.rawValue, targetId: nil, metadata: metadata)
        }
    }

    /// Current graph snapshot (thread-safe copy).
    public func currentSnapshot() -> SessionGraphSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return snapshot
    }

    /// Reset graph to empty state (e.g. after clearAllData).
    public func reset() {
        lock.lock()
        snapshot = SessionGraphSnapshot()
        lastDwellStart = nil
        lastScreenBeforeDwell = nil
        lock.unlock()
    }

    private func computeDwellBefore(_ now: Date) -> TimeInterval {
        guard let start = lastDwellStart else { return 0 }
        return max(0, now.timeIntervalSince(start))
    }

    private func addNode(_ node: GraphNode) {
        snapshot.nodes.insert(node)
        if snapshot.edges[node] == nil {
            snapshot.edges[node] = [:]
        }
        if snapshot.nodeMetadata[node] == nil {
            snapshot.nodeMetadata[node] = NodeMetadata()
        }
    }

    private func addEdge(from: GraphNode, to: GraphNode, dwellBefore: TimeInterval) {
        addNode(from)
        addNode(to)
        if snapshot.edges[from] == nil {
            snapshot.edges[from] = [:]
        }
        var edge = snapshot.edges[from]![to] ?? GraphEdge()
        edge.addTransition(dwellBefore: dwellBefore)
        snapshot.edges[from]![to] = edge
    }

    private func appendRecentScreen(_ node: GraphNode) {
        snapshot.recentScreenSequence.append(node)
        if snapshot.recentScreenSequence.count > recentCapacity {
            snapshot.recentScreenSequence.removeFirst()
        }
    }

    private func appendRecentProduct(_ node: GraphNode) {
        snapshot.recentProductSequence.append(node)
        if snapshot.recentProductSequence.count > recentCapacity {
            snapshot.recentProductSequence.removeFirst()
        }
    }

    private func updateNodeMetadata(_ node: GraphNode, visit: Bool, longDwell: Bool) {
        if snapshot.nodeMetadata[node] == nil {
            snapshot.nodeMetadata[node] = NodeMetadata()
        }
        var meta = snapshot.nodeMetadata[node]!
        if visit {
            meta.totalVisitCount += 1
            meta.lastVisitDate = Date()
        }
        if longDwell {
            meta.longDwellCount += 1
        }
        snapshot.nodeMetadata[node] = meta
    }

    private func setNodeMetadata(
        _ node: GraphNode,
        label: String?,
        kind: String?,
        targetId: String?,
        metadata: [String: String]?
    ) {
        if snapshot.nodeMetadata[node] == nil {
            snapshot.nodeMetadata[node] = NodeMetadata()
        }
        var meta = snapshot.nodeMetadata[node]!
        meta.label = label
        meta.kind = kind
        meta.targetId = targetId
        meta.metadata = metadata
        snapshot.nodeMetadata[node] = meta
    }
}
