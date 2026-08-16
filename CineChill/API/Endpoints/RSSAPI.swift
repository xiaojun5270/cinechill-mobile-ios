// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `RSS` 分组，共 22 个接口。
public struct RSSAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Build Rss Url
    /// `POST /api/rss/build_url`
    @discardableResult
    public func buildRssUrl(_ body: RssBuildUrlRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/rss/build_url", query: nil, body: body)
    }

    /// Get Rss Config
    /// `GET /api/rss/config`
    @discardableResult
    public func getRssConfig() async throws -> JSONValue {
        try await client.send(.get, "/api/rss/config", query: nil)
    }

    /// Create Rss Task
    /// `POST /api/rss/create_task`
    @discardableResult
    public func createRssTask(_ body: RssTaskModel) async throws -> JSONValue {
        try await client.send(.post, "/api/rss/create_task", query: nil, body: body)
    }

    /// Delete Rss Task
    /// `POST /api/rss/delete_task`
    @discardableResult
    public func deleteRssTask(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/rss/delete_task", query: nil, body: body)
    }

    /// Rss Image Proxy
    /// `GET /api/rss/image_proxy`
    public func rssImageProxyURL(url: String) throws -> URL {
        try client.url(path: "/api/rss/image_proxy", query: ["url": Query.value(url)])
    }

    /// Get Rss Link Presets
    /// `GET /api/rss/link_presets`
    @discardableResult
    public func getRssLinkPresets() async throws -> JSONValue {
        try await client.send(.get, "/api/rss/link_presets", query: nil)
    }

    /// Domestic Platform Rss
    /// `GET /api/rss/native/domestic/{platform}`
    @discardableResult
    public func domesticPlatformRss(platform: String, mtype: String? = nil, pageLimit: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/rss/native/domestic/\(Path.escape(platform))", query: ["mtype": Query.value(mtype), "page_limit": Query.value(pageLimit)])
    }

    /// Douban Classification Rss
    /// `GET /api/rss/native/douban/classification`
    @discardableResult
    public func doubanClassificationRss(sort: String? = nil, score: Double? = nil, tags: String? = nil, pageLimit: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/rss/native/douban/classification", query: ["sort": Query.value(sort), "score": Query.value(score), "tags": Query.value(tags), "page_limit": Query.value(pageLimit)])
    }

    /// Douban Coming Rss
    /// `GET /api/rss/native/douban/coming`
    @discardableResult
    public func doubanComingRss() async throws -> JSONValue {
        try await client.send(.get, "/api/rss/native/douban/coming", query: nil)
    }

    /// Douban List Rss
    /// `GET /api/rss/native/douban/list`
    @discardableResult
    public func doubanListRss(collectionId: String? = nil, mediaType: String? = nil, score: Double? = nil, playable: Int? = nil, pageLimit: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/rss/native/douban/list", query: ["collection_id": Query.value(collectionId), "media_type": Query.value(mediaType), "score": Query.value(score), "playable": Query.value(playable), "page_limit": Query.value(pageLimit)])
    }

    /// Douban Recommended Rss
    /// `GET /api/rss/native/douban/recommended`
    @discardableResult
    public func doubanRecommendedRss(subjectType: String? = nil, score: Double? = nil, playable: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/rss/native/douban/recommended", query: ["subject_type": Query.value(subjectType), "score": Query.value(score), "playable": Query.value(playable)])
    }

    /// Iqiyi Rank Rss
    /// `GET /api/rss/native/iqiyi/rank`
    @discardableResult
    public func iqiyiRankRss(category: String? = nil, rank: String? = nil, pageLimit: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/rss/native/iqiyi/rank", query: ["category": Query.value(category), "rank": Query.value(rank), "page_limit": Query.value(pageLimit)])
    }

    /// Maoyan Movie Rss
    /// `GET /api/rss/native/maoyan/movie`
    @discardableResult
    public func maoyanMovieRss(kind: String? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/rss/native/maoyan/movie", query: ["kind": Query.value(kind)])
    }

    /// Maoyan Platform Rss
    /// `GET /api/rss/native/maoyan/platform`
    @discardableResult
    public func maoyanPlatformRss(platform: String? = nil, rank: String? = nil, pageLimit: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/rss/native/maoyan/platform", query: ["platform": Query.value(platform), "rank": Query.value(rank), "page_limit": Query.value(pageLimit)])
    }

    /// Tmdb Discover Rss
    /// `GET /api/rss/native/tmdb/discover`
    @discardableResult
    public func tmdbDiscoverRss(mediaType: String? = nil, watchProvider: String? = nil, watchRegion: String? = nil, sortBy: String? = nil, language: String? = nil, pageLimit: Int? = nil, maxItems: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/rss/native/tmdb/discover", query: ["media_type": Query.value(mediaType), "watch_provider": Query.value(watchProvider), "watch_region": Query.value(watchRegion), "sort_by": Query.value(sortBy), "language": Query.value(language), "page_limit": Query.value(pageLimit), "max_items": Query.value(maxItems)])
    }

    /// Tmdb Trending Rss
    /// `GET /api/rss/native/tmdb/trending`
    @discardableResult
    public func tmdbTrendingRss(mediaType: String? = nil, timeWindow: String? = nil, language: String? = nil, pageLimit: Int? = nil, maxItems: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/rss/native/tmdb/trending", query: ["media_type": Query.value(mediaType), "time_window": Query.value(timeWindow), "language": Query.value(language), "page_limit": Query.value(pageLimit), "max_items": Query.value(maxItems)])
    }

    /// Preview Rss Url
    /// `POST /api/rss/preview`
    @discardableResult
    public func previewRssUrl(_ body: RssPreviewRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/rss/preview", query: nil, body: body)
    }

    /// Run Rss Now
    /// `POST /api/rss/run_now`
    @discardableResult
    public func runRssNow(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/rss/run_now", query: nil, body: body)
    }

    /// Save Rss Config
    /// `POST /api/rss/save_config`
    @discardableResult
    public func saveRssConfig(_ body: RssGlobalConfig) async throws -> JSONValue {
        try await client.send(.post, "/api/rss/save_config", query: nil, body: body)
    }

    /// Get Rss Tasks
    /// `GET /api/rss/tasks`
    @discardableResult
    public func getRssTasks() async throws -> JSONValue {
        try await client.send(.get, "/api/rss/tasks", query: nil)
    }

    /// Toggle Rss Task Endpoint
    /// `POST /api/rss/toggle_task`
    @discardableResult
    public func toggleRssTaskEndpoint(_ body: ToggleTaskRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/rss/toggle_task", query: nil, body: body)
    }

    /// Update Rss Task
    /// `POST /api/rss/update_task`
    @discardableResult
    public func updateRssTask(_ body: UpdateRssTaskRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/rss/update_task", query: nil, body: body)
    }

}
