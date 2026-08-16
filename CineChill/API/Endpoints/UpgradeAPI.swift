// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `Upgrade` 分组，共 3 个接口。
public struct UpgradeAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Upgrade Check
    /// `POST /api/upgrade/check`
    @discardableResult
    public func upgradeCheck(_ body: UpgradeCheckRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/upgrade/check", query: nil, body: body)
    }

    /// Upgrade Start
    /// `POST /api/upgrade/start`
    @discardableResult
    public func upgradeStart(_ body: UpgradeStartRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/upgrade/start", query: nil, body: body)
    }

    /// Upgrade Status
    /// `GET /api/upgrade/status`
    @discardableResult
    public func upgradeStatus() async throws -> JSONValue {
        try await client.send(.get, "/api/upgrade/status", query: nil)
    }

}
