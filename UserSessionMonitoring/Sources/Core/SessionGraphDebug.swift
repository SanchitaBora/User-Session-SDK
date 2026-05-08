import Foundation

extension GraphNode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .screen(let id):
            return "screen(\(id))"
        case .product(let id):
            return "product(\(id))"
        case .screenProduct(let screenId, let productId):
            return "screenProduct(\(screenId),\(productId))"
        case .action(let id):
            return "action(\(id))"
        }
    }
}

extension SessionGraphSnapshot {
    /// Human-readable dump for debugging (console or on-screen).
    public func formattedDebugDescription() -> String {
        var lines: [String] = []
        lines.append("=== Session graph snapshot ===")
        lines.append("Nodes (\(nodes.count)):")
        for node in nodes.map(\.description).sorted() {
            lines.append("  • \(node)")
        }
        lines.append("")
        lines.append("Edges (from → to):")
        let sortedFrom = edges.keys.sorted { $0.description < $1.description }
        var edgeCount = 0
        for from in sortedFrom {
            guard let destMap = edges[from] else { continue }
            let pairs = destMap.map { ($0.key, $0.value) }.sorted { $0.0.description < $1.0.description }
            for (to, edge) in pairs {
                edgeCount += 1
                let avg = String(format: "%.2f", edge.avgDwellBefore)
                lines.append(
                    "  \(from.description) → \(to.description)  transitions=\(edge.transitionCount) avgDwellBefore=\(avg)s"
                )
            }
        }
        if edgeCount == 0 {
            lines.append("  (none)")
        }
        lines.append("")
        lines.append("Recent screen path (\(recentScreenSequence.count)):")
        lines.append("  \(recentScreenSequence.map(\.description).joined(separator: " → "))")
        lines.append("Recent product path (\(recentProductSequence.count)):")
        lines.append("  \(recentProductSequence.map(\.description).joined(separator: " → "))")
        lines.append("Last screen node: \(lastScreenNode.map(\.description) ?? "nil")")
        lines.append("Node metadata (visits / long dwell):")
        let metaKeys = nodeMetadata.keys.sorted { $0.description < $1.description }
        for key in metaKeys {
            guard let m = nodeMetadata[key] else { continue }
            var extras: [String] = []
            if let kind = m.kind { extras.append("kind=\(kind)") }
            if let label = m.label { extras.append("label=\(label)") }
            if let targetId = m.targetId { extras.append("targetId=\(targetId)") }
            lines.append("  \(key.description): visits=\(m.totalVisitCount) longDwell=\(m.longDwellCount)\(extras.isEmpty ? "" : " " + extras.joined(separator: " "))")
        }
        if metaKeys.isEmpty {
            lines.append("  (none)")
        }
        return lines.joined(separator: "\n")
    }
}
