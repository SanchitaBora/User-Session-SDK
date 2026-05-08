import Foundation
import Core

/// Main entry point for the User Session SDK.
public enum SessionSDK {
    private static let lock = NSLock()
    private static var _shared: SessionSDKInstance?

    /// Start the SDK with the given configuration. Call once at app launch.
    public static func start(config: SessionSDKConfiguration) {
        lock.lock()
        _shared = SessionSDKInstance(config: config)
        lock.unlock()
    }

    /// Track an event. No-op if SDK has not been started.
    public static func track(_ event: SessionEvent) {
        lock.lock()
        let instance = _shared
        lock.unlock()
        instance?.collector.track(event)
    }

    /// Clear all local data for the current tenant. Does not stop the SDK.
    public static func clearAllData() {
        lock.lock()
        let instance = _shared
        lock.unlock()
        instance?.clearAllData()
    }

    /// Current in-memory session graph (for debugging). `nil` if `start` has not been called.
    public static func currentSessionGraphSnapshot() -> SessionGraphSnapshot? {
        lock.lock()
        let instance = _shared
        lock.unlock()
        return instance.map { $0.graphBuilder.currentSnapshot() }
    }
}

final class SessionSDKInstance {
    let config: SessionSDKConfiguration
    let store: LocalEventStore
    let graphBuilder: SessionGraphBuilder
    let collector: EventCollector

    init(config: SessionSDKConfiguration) {
        self.config = config
        self.store = LocalEventStore()
        self.graphBuilder = SessionGraphBuilder()
        self.collector = EventCollector(
            store: store,
            graphBuilder: graphBuilder,
            config: config
        )
    }

    func clearAllData() {
        store.clear()
        graphBuilder.reset()
    }
}
