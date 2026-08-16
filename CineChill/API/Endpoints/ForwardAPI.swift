// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `ForwardAiying` 分组，共 13 个接口。
public struct ForwardAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Get Config
    /// `GET /api/forward/config`
    @discardableResult
    public func getConfig() async throws -> JSONValue {
        try await client.send(.get, "/api/forward/config", query: nil)
    }

    /// Save Config
    /// `POST /api/forward/config`
    @discardableResult
    public func saveConfig(_ body: ForwardConfigRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/forward/config", query: nil, body: body)
    }

    /// Download Forward Resource
    /// `POST /api/forward/download_resource`
    @discardableResult
    public func downloadForwardResource(_ body: ResourceDownloadRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/forward/download_resource", query: nil, body: body)
    }

    /// Play Forward Resource
    /// `GET /api/forward/play`
    public func playForwardResourceURL(token: String? = nil, source: String? = nil, resourceId: String? = nil, `type`: String? = nil, tmdbId: String? = nil, season: Int? = nil, episode: Int? = nil, ignoreEnabled: Bool? = nil) throws -> URL {
        try client.url(path: "/api/forward/play", query: ["token": Query.value(token), "source": Query.value(source), "resource_id": Query.value(resourceId), "type": Query.value(`type`), "tmdb_id": Query.value(tmdbId), "season": Query.value(season), "episode": Query.value(episode), "ignore_enabled": Query.value(ignoreEnabled)])
    }

    /// Preview Forward Resource
    /// `POST /api/forward/preview_resource`
    @discardableResult
    public func previewForwardResource(_ body: ResourcePreviewRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/forward/preview_resource", query: nil, body: body)
    }

    /// Load Forward Resources
    /// `POST /api/forward/resources`
    @discardableResult
    public func loadForwardResources(token: String? = nil) async throws -> JSONValue {
        try await client.send(.post, "/api/forward/resources", query: ["token": Query.value(token)])
    }

    /// Search Forward Resources
    /// `POST /api/forward/search_resources`
    @discardableResult
    public func searchForwardResources(_ body: ResourceSearchRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/forward/search_resources", query: nil, body: body)
    }

    /// Stream Forward Resources
    /// `POST /api/forward/search_resources/stream`
    public func streamForwardResourcesRequest(_ body: ResourceSearchRequest) throws -> URLRequest {
        try client.streamRequest(method: .post, path: "/api/forward/search_resources/stream", query: nil, body: body)
    }

    /// Get Search Sources
    /// `GET /api/forward/search_sources`
    @discardableResult
    public func getSearchSources() async throws -> JSONValue {
        try await client.send(.get, "/api/forward/search_sources", query: nil)
    }

    /// Test Resources
    /// `POST /api/forward/test_resources`
    @discardableResult
    public func testResources(_ body: ResourceTestRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/forward/test_resources", query: nil, body: body)
    }

    /// Refresh Widget Token
    /// `POST /api/forward/token/refresh`
    @discardableResult
    public func refreshWidgetToken() async throws -> JSONValue {
        try await client.send(.post, "/api/forward/token/refresh", query: nil)
    }

    /// Transfer Forward Resource
    /// `POST /api/forward/transfer_resource`
    @discardableResult
    public func transferForwardResource(_ body: ResourceTransferRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/forward/transfer_resource", query: nil, body: body)
    }

    /// Widget Js
    /// `GET /api/forward/widget.js`
    public func widgetJsURL(token: String? = nil) throws -> URL {
        try client.url(path: "/api/forward/widget.js", query: ["token": Query.value(token)])
    }

}
