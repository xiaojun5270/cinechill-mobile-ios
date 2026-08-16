// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `Auth` 分组，共 4 个接口。
public struct AuthAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Change Auth
    /// `POST /api/change_auth`
    @discardableResult
    public func changeAuth(_ body: ChangeAuthRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/change_auth", query: nil, body: body)
    }

    /// Login
    /// `POST /api/login`
    @discardableResult
    public func login(_ body: LoginRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/login", query: nil, body: body)
    }

    /// Logout
    /// `POST /api/logout`
    @discardableResult
    public func logout() async throws -> JSONValue {
        try await client.send(.post, "/api/logout", query: nil)
    }

    /// Get User Info
    /// `GET /api/user_info`
    @discardableResult
    public func getUserInfo() async throws -> JSONValue {
        try await client.send(.get, "/api/user_info", query: nil)
    }

}
