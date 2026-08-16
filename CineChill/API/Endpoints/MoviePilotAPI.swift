// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `MoviePilot` 分组，共 7 个接口。
public struct MoviePilotAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Get Mp Config
    /// `GET /api/moviepilot/config`
    @discardableResult
    public func getMpConfig() async throws -> JSONValue {
        try await client.send(.get, "/api/moviepilot/config", query: nil)
    }

    /// Save Mp Config
    /// `POST /api/moviepilot/config`
    @discardableResult
    public func saveMpConfig(_ body: MoviePilotConfigModel) async throws -> JSONValue {
        try await client.send(.post, "/api/moviepilot/config", query: nil, body: body)
    }

    /// Mp List Subscriptions
    /// `GET /api/moviepilot/subscribe`
    @discardableResult
    public func mpListSubscriptions() async throws -> JSONValue {
        try await client.send(.get, "/api/moviepilot/subscribe", query: nil)
    }

    /// Mp Subscribe
    /// `POST /api/moviepilot/subscribe`
    @discardableResult
    public func mpSubscribe(_ body: SubscribeRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/moviepilot/subscribe", query: nil, body: body)
    }

    /// Mp Unsubscribe
    /// `DELETE /api/moviepilot/subscribe`
    @discardableResult
    public func mpUnsubscribe(tmdbid: Int, typeName: String? = nil, season: Int? = nil) async throws -> JSONValue {
        try await client.send(.delete, "/api/moviepilot/subscribe", query: ["tmdbid": Query.value(tmdbid), "type_name": Query.value(typeName), "season": Query.value(season)])
    }

    /// Mp Check Subscribe
    /// `GET /api/moviepilot/subscribe/check`
    @discardableResult
    public func mpCheckSubscribe(tmdbid: Int, typeName: String? = nil, season: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/moviepilot/subscribe/check", query: ["tmdbid": Query.value(tmdbid), "type_name": Query.value(typeName), "season": Query.value(season)])
    }

    /// Test Mp Connection
    /// `POST /api/moviepilot/test`
    @discardableResult
    public func testMpConnection() async throws -> JSONValue {
        try await client.send(.post, "/api/moviepilot/test", query: nil)
    }

}
