// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `Discover` 分组，共 40 个接口。
public struct DiscoverAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Bangumi Image Proxy
    /// 代理转发 Bangumi 图片，代理异常时回退直连。
    /// `GET /api/discover/bangumi_img`
    public func bangumiImageProxyURL(url: String) throws -> URL {
        try client.url(path: "/api/discover/bangumi_img", query: ["url": Query.value(url)])
    }

    /// Bili Image Proxy
    /// 代理转发哔哩哔哩图片
    /// `GET /api/discover/bili_img`
    public func biliImageProxyURL(url: String) throws -> URL {
        try client.url(path: "/api/discover/bili_img", query: ["url": Query.value(url)])
    }

    /// Cached Configured Image Proxy
    /// 缓存已配置 Emby 服务器图片，供缺集统计等页面复用本地图片缓存。
    /// `GET /api/discover/cached_img`
    public func cachedConfiguredImageProxyURL(url: String) throws -> URL {
        try client.url(path: "/api/discover/cached_img", query: ["url": Query.value(url)])
    }

    /// Media Detail
    /// `GET /api/discover/detail/{tmdb_id}`
    @discardableResult
    public func mediaDetail(tmdbId: Int, `type`: String? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/detail/\(Path.escape(String(tmdbId)))", query: ["type": Query.value(`type`)])
    }

    /// Discover By Genre
    /// 按类型筛选，缓存 30min
    /// `GET /api/discover/discover_by_genre`
    @discardableResult
    public func discoverByGenre(genreId: Int, mediaType: String? = nil, page: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/discover_by_genre", query: ["genre_id": Query.value(genreId), "media_type": Query.value(mediaType), "page": Query.value(page)])
    }

    /// Douban Chinese Weekly
    /// `GET /api/discover/douban/chinese_weekly`
    @discardableResult
    public func doubanChineseWeekly(start: Int? = nil, count: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/douban/chinese_weekly", query: ["start": Query.value(start), "count": Query.value(count)])
    }

    /// Douban Global Weekly
    /// `GET /api/discover/douban/global_weekly`
    @discardableResult
    public func doubanGlobalWeekly(start: Int? = nil, count: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/douban/global_weekly", query: ["start": Query.value(start), "count": Query.value(count)])
    }

    /// Douban Hot Anime
    /// `GET /api/discover/douban/hot_anime`
    @discardableResult
    public func doubanHotAnime(start: Int? = nil, count: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/douban/hot_anime", query: ["start": Query.value(start), "count": Query.value(count)])
    }

    /// Douban Hot Movies
    /// `GET /api/discover/douban/hot_movies`
    @discardableResult
    public func doubanHotMovies(start: Int? = nil, count: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/douban/hot_movies", query: ["start": Query.value(start), "count": Query.value(count)])
    }

    /// Douban Hot Tv
    /// `GET /api/discover/douban/hot_tv`
    @discardableResult
    public func doubanHotTv(start: Int? = nil, count: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/douban/hot_tv", query: ["start": Query.value(start), "count": Query.value(count)])
    }

    /// Douban New Movies
    /// `GET /api/discover/douban/new_movies`
    @discardableResult
    public func doubanNewMovies(start: Int? = nil, count: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/douban/new_movies", query: ["start": Query.value(start), "count": Query.value(count)])
    }

    /// Douban New Tv
    /// `GET /api/discover/douban/new_tv`
    @discardableResult
    public func doubanNewTv(start: Int? = nil, count: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/douban/new_tv", query: ["start": Query.value(start), "count": Query.value(count)])
    }

    /// Douban Showing
    /// `GET /api/discover/douban/showing`
    @discardableResult
    public func doubanShowing(start: Int? = nil, count: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/douban/showing", query: ["start": Query.value(start), "count": Query.value(count)])
    }

    /// Douban Top250
    /// `GET /api/discover/douban/top250`
    @discardableResult
    public func doubanTop250(start: Int? = nil, count: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/douban/top250", query: ["start": Query.value(start), "count": Query.value(count)])
    }

    /// Douban Image Proxy
    /// 代理转发豆瓣图片
    /// `GET /api/discover/douban_img`
    public func doubanImageProxyURL(url: String) throws -> URL {
        try client.url(path: "/api/discover/douban_img", query: ["url": Query.value(url)])
    }

    /// Delete Emby Series Items
    /// `POST /api/discover/emby/items/delete`
    @discardableResult
    public func deleteEmbySeriesItems(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/discover/emby/items/delete", query: nil, body: body)
    }

    /// Emby Cover Proxy
    /// 代理 Emby 封面图，供企业微信等外部服务抓取（带 HMAC 签名保护）
    /// `GET /api/discover/emby_cover`
    public func embyCoverProxyURL(serverIdx: Int, itemId: String, ts: Int, sig: String) throws -> URL {
        try client.url(path: "/api/discover/emby_cover", query: ["server_idx": Query.value(serverIdx), "item_id": Query.value(itemId), "ts": Query.value(ts), "sig": Query.value(sig)])
    }

    /// Get Emby Web Url
    /// `GET /api/discover/emby_web_url`
    @discardableResult
    public func getEmbyWebUrl(serverIdx: Int? = nil, itemId: String) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/emby_web_url", query: ["server_idx": Query.value(serverIdx), "item_id": Query.value(itemId)])
    }

    /// Discover Realtime Events
    /// `GET /api/discover/events`
    public func discoverRealtimeEventsRequest() throws -> URLRequest {
        try client.streamRequest(method: .get, path: "/api/discover/events", query: nil)
    }

    /// Get Genres
    /// 合并电影+剧集类型列表，缓存 24h
    /// `GET /api/discover/genres`
    @discardableResult
    public func getGenres() async throws -> JSONValue {
        try await client.send(.get, "/api/discover/genres", query: nil)
    }

    /// Check Library Exists
    /// `POST /api/discover/library/exists`
    @discardableResult
    public func checkLibraryExists(_ body: JSONValue, resolveMissing: Bool? = nil) async throws -> JSONValue {
        try await client.send(.post, "/api/discover/library/exists", query: ["resolve_missing": Query.value(resolveMissing)], body: body)
    }

    /// Library Missing Episode Stats
    /// `GET /api/discover/library/missing-episode-stats`
    @discardableResult
    public func libraryMissingEpisodeStats(refresh: Int? = nil, start: Int? = nil, summaryOnly: Int? = nil, seasonMode: String? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/library/missing-episode-stats", query: ["refresh": Query.value(refresh), "start": Query.value(start), "summary_only": Query.value(summaryOnly), "season_mode": Query.value(seasonMode)])
    }

    /// Set Missing Episode Manual Complete
    /// `POST /api/discover/library/missing-episode-stats/manual-complete`
    @discardableResult
    public func setMissingEpisodeManualComplete(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/discover/library/missing-episode-stats/manual-complete", query: nil, body: body)
    }

    /// Library Series Status
    /// `GET /api/discover/library/series/{tmdb_id}`
    @discardableResult
    public func librarySeriesStatus(tmdbId: Int) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/library/series/\(Path.escape(String(tmdbId)))", query: nil)
    }

    /// Discover Provider
    /// `GET /api/discover/provider/{source_key}`
    @discardableResult
    public func discoverProvider(sourceKey: String) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/provider/\(Path.escape(sourceKey))", query: nil)
    }

    /// Resolve Douban To Tmdb
    /// 批量将外部来源条目解析为 TMDB ID。
    /// 输入: [{"title": "xxx", "year": "2024", "media_type": "movie"}, ...]
    /// 返回: {"results": {"xxx_2024": 12345, ...}}
    /// `POST /api/discover/resolve_tmdb`
    @discardableResult
    public func resolveDoubanToTmdb(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/discover/resolve_tmdb", query: nil, body: body)
    }

    /// Search Media
    /// `GET /api/discover/search`
    @discardableResult
    public func searchMedia(query: String, `type`: String? = nil, page: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/search", query: ["query": Query.value(query), "type": Query.value(`type`), "page": Query.value(page)])
    }

    /// Get Discover Sources
    /// `GET /api/discover/sources`
    @discardableResult
    public func getDiscoverSources() async throws -> JSONValue {
        try await client.send(.get, "/api/discover/sources", query: nil)
    }

    /// Task Cover Preview
    /// `GET /api/discover/task_cover`
    public func taskCoverPreviewURL(key: String) throws -> URL {
        try client.url(path: "/api/discover/task_cover", query: ["key": Query.value(key)])
    }

    /// Tmdb Discover
    /// TMDB 通用发现接口，支持完整筛选参数
    /// `GET /api/discover/tmdb/discover`
    @discardableResult
    public func tmdbDiscover(mediaType: String? = nil, sortBy: String? = nil, withGenres: String? = nil, withKeywords: String? = nil, withOriginalLanguage: String? = nil, withWatchProviders: String? = nil, voteAverage: Double? = nil, voteCount: Int? = nil, releaseDate: String? = nil, page: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/tmdb/discover", query: ["media_type": Query.value(mediaType), "sort_by": Query.value(sortBy), "with_genres": Query.value(withGenres), "with_keywords": Query.value(withKeywords), "with_original_language": Query.value(withOriginalLanguage), "with_watch_providers": Query.value(withWatchProviders), "vote_average": Query.value(voteAverage), "vote_count": Query.value(voteCount), "release_date": Query.value(releaseDate), "page": Query.value(page)])
    }

    /// Tmdb Now Playing
    /// `GET /api/discover/tmdb/now_playing`
    @discardableResult
    public func tmdbNowPlaying(page: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/tmdb/now_playing", query: ["page": Query.value(page)])
    }

    /// Tmdb Popular Movies
    /// `GET /api/discover/tmdb/popular_movies`
    @discardableResult
    public func tmdbPopularMovies(page: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/tmdb/popular_movies", query: ["page": Query.value(page)])
    }

    /// Tmdb Popular Tv
    /// `GET /api/discover/tmdb/popular_tv`
    @discardableResult
    public func tmdbPopularTv(page: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/tmdb/popular_tv", query: ["page": Query.value(page)])
    }

    /// Tmdb Trending
    /// `GET /api/discover/tmdb/trending`
    @discardableResult
    public func tmdbTrending(page: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/tmdb/trending", query: ["page": Query.value(page)])
    }

    /// Tmdb Artwork Batch
    /// `POST /api/discover/tmdb_artwork/batch`
    @discardableResult
    public func tmdbArtworkBatch(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/discover/tmdb_artwork/batch", query: nil, body: body)
    }

    /// Tmdb Backdrop Image
    /// `GET /api/discover/tmdb_backdrop/{media_type}/{tmdb_id}`
    public func tmdbBackdropImageURL(mediaType: String, tmdbId: Int) throws -> URL {
        try client.url(path: "/api/discover/tmdb_backdrop/\(Path.escape(mediaType))/\(Path.escape(String(tmdbId)))", query: nil)
    }

    /// Tmdb Image Proxy
    /// 代理转发 TMDB 图片，解决国内无法访问 image.tmdb.org 的问题
    /// `GET /api/discover/tmdb_img`
    public func tmdbImageProxyURL(path: String) throws -> URL {
        try client.url(path: "/api/discover/tmdb_img", query: ["path": Query.value(path)])
    }

    /// Tmdb Poster Image
    /// `GET /api/discover/tmdb_poster/{media_type}/{tmdb_id}`
    public func tmdbPosterImageURL(mediaType: String, tmdbId: Int) throws -> URL {
        try client.url(path: "/api/discover/tmdb_poster/\(Path.escape(mediaType))/\(Path.escape(String(tmdbId)))", query: nil)
    }

    /// Today Picks
    /// 今日推荐：随机选 20 条热门电影，每天内容不同，缓存到当天结束
    /// `GET /api/discover/today_picks`
    @discardableResult
    public func todayPicks() async throws -> JSONValue {
        try await client.send(.get, "/api/discover/today_picks", query: nil)
    }

    /// Season Detail
    /// `GET /api/discover/tv/{tmdb_id}/season/{season_num}`
    @discardableResult
    public func seasonDetail(tmdbId: Int, seasonNum: Int) async throws -> JSONValue {
        try await client.send(.get, "/api/discover/tv/\(Path.escape(String(tmdbId)))/season/\(Path.escape(String(seasonNum)))", query: nil)
    }

}
