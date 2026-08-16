// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `Server` 分组，共 13 个接口。
public struct ServerAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Connect
    /// `POST /api/connect`
    @discardableResult
    public func connect(_ body: ConnectionRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/connect", query: nil, body: body)
    }

    /// Get Dashboard 115 Account
    /// `GET /api/dashboard_115_account`
    @discardableResult
    public func getDashboard115Account() async throws -> JSONValue {
        try await client.send(.get, "/api/dashboard_115_account", query: nil)
    }

    /// Get Dashboard Device Metrics
    /// `GET /api/dashboard_device_metrics`
    @discardableResult
    public func getDashboardDeviceMetrics() async throws -> JSONValue {
        try await client.send(.get, "/api/dashboard_device_metrics", query: nil)
    }

    /// Get Dashboard Emby Overview
    /// `POST /api/dashboard_emby_overview`
    @discardableResult
    public func getDashboardEmbyOverview(_ body: ConnectionRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/dashboard_emby_overview", query: nil, body: body)
    }

    /// Get Dashboard Stats
    /// `GET /api/dashboard_stats`
    @discardableResult
    public func getDashboardStats() async throws -> JSONValue {
        try await client.send(.get, "/api/dashboard_stats", query: nil)
    }

    /// Emby Get Images
    /// `POST /api/emby/get_images`
    @discardableResult
    public func embyGetImages(_ body: EmbyItemImagesRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/emby/get_images", query: nil, body: body)
    }

    /// Emby Random Pool
    /// `POST /api/emby/random_pool`
    @discardableResult
    public func embyRandomPool(_ body: EmbyRandomPoolRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/emby/random_pool", query: nil, body: body)
    }

    /// Emby Search
    /// `POST /api/emby/search`
    @discardableResult
    public func embySearch(_ body: EmbySearchRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/emby/search", query: nil, body: body)
    }

    /// Get Library Covers
    /// `POST /api/library_covers`
    @discardableResult
    public func getLibraryCovers(_ body: ConnectionRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/library_covers", query: nil, body: body)
    }

    /// Load Config
    /// `GET /api/load`
    @discardableResult
    public func loadConfig() async throws -> JSONValue {
        try await client.send(.get, "/api/load", query: nil)
    }

    /// Test Proxy Connection
    /// `POST /api/proxy/test`
    @discardableResult
    public func testProxyConnection(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/proxy/test", query: nil, body: body)
    }

    /// Save Config
    /// `POST /api/save`
    @discardableResult
    public func saveConfig(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/save", query: nil, body: body)
    }

    /// Restart Server
    /// 重启服务（用于网关端口变更后生效）
    /// `POST /api/server/restart`
    @discardableResult
    public func restartServer() async throws -> JSONValue {
        try await client.send(.post, "/api/server/restart", query: nil)
    }

}
