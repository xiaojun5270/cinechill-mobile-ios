// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `FnosSign` 分组，共 5 个接口。
public struct FnosSignAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Update Fnos Sign Config
    /// `POST /api/fnos_sign/config`
    @discardableResult
    public func updateFnosSignConfig(_ body: FnosSignConfigPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/fnos_sign/config", query: nil, body: body)
    }

    /// Clear Fnos Sign History
    /// `DELETE /api/fnos_sign/history`
    @discardableResult
    public func clearFnosSignHistory() async throws -> JSONValue {
        try await client.send(.delete, "/api/fnos_sign/history", query: nil)
    }

    /// Run Fnos Sign
    /// `POST /api/fnos_sign/run`
    @discardableResult
    public func runFnosSign(_ body: FnosSignRunPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/fnos_sign/run", query: nil, body: body)
    }

    /// Get Fnos Sign State
    /// `GET /api/fnos_sign/state`
    @discardableResult
    public func getFnosSignState() async throws -> JSONValue {
        try await client.send(.get, "/api/fnos_sign/state", query: nil)
    }

    /// Test Fnos Sign Cookie
    /// `POST /api/fnos_sign/test_cookie`
    @discardableResult
    public func testFnosSignCookie(_ body: FnosSignCookiePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/fnos_sign/test_cookie", query: nil, body: body)
    }

}
