// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `public` 分组，共 2 个接口。
public struct PublicAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Get Login Posters
    /// `GET /api/public/login-posters`
    @discardableResult
    public func getLoginPosters() async throws -> JSONValue {
        try await client.send(.get, "/api/public/login-posters", query: nil)
    }

    /// Get Login Poster Image
    /// `GET /api/public/login-posters/{item_id}/poster`
    public func getLoginPosterImageURL(itemId: String, tag: String? = nil, w: Int? = nil) throws -> URL {
        try client.url(path: "/api/public/login-posters/\(Path.escape(itemId))/poster", query: ["tag": Query.value(tag), "w": Query.value(w)])
    }

}
