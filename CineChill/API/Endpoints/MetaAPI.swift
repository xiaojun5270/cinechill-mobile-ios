// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `untagged` 分组，共 4 个接口。
public struct MetaAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Api Version
    /// `GET /api/version`
    @discardableResult
    public func apiVersion() async throws -> JSONValue {
        try await client.send(.get, "/api/version", query: nil)
    }

}
