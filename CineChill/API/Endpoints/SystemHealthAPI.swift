// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `SystemHealth` 分组，共 5 个接口。
public struct SystemHealthAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Get System Health
    /// `GET /api/system_health`
    @discardableResult
    public func getSystemHealth(targetId: String? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/system_health", query: ["target_id": Query.value(targetId)])
    }

    /// Get Network Connectivity
    /// `GET /api/system_health/network`
    @discardableResult
    public func getNetworkConnectivity(targetId: String? = nil, full: Bool? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/system_health/network", query: ["target_id": Query.value(targetId), "full": Query.value(full)])
    }

    /// Get Last Network Connectivity
    /// `GET /api/system_health/network/last`
    @discardableResult
    public func getLastNetworkConnectivity() async throws -> JSONValue {
        try await client.send(.get, "/api/system_health/network/last", query: nil)
    }

    /// Get Network Connectivity Targets
    /// `GET /api/system_health/network/targets`
    @discardableResult
    public func getNetworkConnectivityTargets(full: Bool? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/system_health/network/targets", query: ["full": Query.value(full)])
    }

    /// Get System Health Targets
    /// `GET /api/system_health/targets`
    @discardableResult
    public func getSystemHealthTargets() async throws -> JSONValue {
        try await client.send(.get, "/api/system_health/targets", query: nil)
    }

}
