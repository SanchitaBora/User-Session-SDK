import Foundation

/// Configuration for the User Session SDK (on-device only).
public struct SessionSDKConfiguration {
    /// Unique identifier for the tenant (app / organization).
    public let tenantId: String

    public init(tenantId: String) {
        self.tenantId = tenantId
    }
}
