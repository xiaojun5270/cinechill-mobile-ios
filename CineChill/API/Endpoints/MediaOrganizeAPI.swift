// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `media_organize` 分组，共 14 个接口。
public struct MediaOrganizeAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Get Default Category Rules
    /// `GET /api/media_organize/category_rules/defaults`
    @discardableResult
    public func getDefaultCategoryRules() async throws -> JSONValue {
        try await client.send(.get, "/api/media_organize/category_rules/defaults", query: nil)
    }

    /// Get Category Rules
    /// `GET /api/media_organize/category_rules/get`
    @discardableResult
    public func getCategoryRules() async throws -> JSONValue {
        try await client.send(.get, "/api/media_organize/category_rules/get", query: nil)
    }

    /// Save Category Rules
    /// `POST /api/media_organize/category_rules/save`
    @discardableResult
    public func saveCategoryRules(_ body: CategoryRulesPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/media_organize/category_rules/save", query: nil, body: body)
    }

    /// Save Sub Classify
    /// 单独保存子分类设置（含 Emby 同步配置）
    /// `POST /api/media_organize/category_rules/sub_classify/save`
    @discardableResult
    public func saveSubClassify(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/media_organize/category_rules/sub_classify/save", query: nil, body: body)
    }

    /// Backfill Movie Collections
    /// 启动已有电影合集补齐任务。
    /// `POST /api/media_organize/collections/backfill`
    @discardableResult
    public func backfillMovieCollections() async throws -> JSONValue {
        try await client.send(.post, "/api/media_organize/collections/backfill", query: nil)
    }

    /// Get Default Config
    /// `GET /api/media_organize/defaults`
    @discardableResult
    public func getDefaultConfig() async throws -> JSONValue {
        try await client.send(.get, "/api/media_organize/defaults", query: nil)
    }

    /// Refresh Emby Lib Cache
    /// 手动刷新 Emby 媒体库缓存
    /// `POST /api/media_organize/emby_lib_cache/refresh`
    @discardableResult
    public func refreshEmbyLibCache() async throws -> JSONValue {
        try await client.send(.post, "/api/media_organize/emby_lib_cache/refresh", query: nil)
    }

    /// Fix Emby Library Locale Defaults
    /// 一次性修复已有 Emby 媒体库的语言/地区默认值。
    /// `POST /api/media_organize/emby_libraries/fix_locale_defaults`
    @discardableResult
    public func fixEmbyLibraryLocaleDefaults(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/media_organize/emby_libraries/fix_locale_defaults", query: nil, body: body)
    }

    /// Sync Emby Library Scrapers
    /// 同步已有 Emby 媒体库的联网刮削器开关，并关闭 Emby 实时监控。
    /// `POST /api/media_organize/emby_libraries/sync_scrapers`
    @discardableResult
    public func syncEmbyLibraryScrapers(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/media_organize/emby_libraries/sync_scrapers", query: nil, body: body)
    }

    /// Get Config
    /// 读取媒体整理配置
    /// `GET /api/media_organize/get`
    @discardableResult
    public func getConfig() async throws -> JSONValue {
        try await client.send(.get, "/api/media_organize/get", query: nil)
    }

    /// Identify Test
    /// 测试媒体名称识别，不移动文件，不写入整理结果。
    /// `POST /api/media_organize/identify_test`
    @discardableResult
    public func identifyTest(_ body: IdentifyTestPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/media_organize/identify_test", query: nil, body: body)
    }

    /// Get Metadata Repair Tv Libraries
    /// 实时读取 Emby 剧集媒体库，返回元数据补齐可用的本地相对范围。
    /// `GET /api/media_organize/metadata_repair/tv_libraries`
    @discardableResult
    public func getMetadataRepairTvLibraries() async throws -> JSONValue {
        try await client.send(.get, "/api/media_organize/metadata_repair/tv_libraries", query: nil)
    }

    /// Organize Media
    /// 启动后台整理任务，立即返回 run_id
    /// `POST /api/media_organize/organize`
    @discardableResult
    public func organizeMedia(_ body: OrganizeRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/media_organize/organize", query: nil, body: body)
    }

    /// Save Config
    /// 保存媒体整理配置
    /// `POST /api/media_organize/save`
    @discardableResult
    public func saveConfig(_ body: MediaOrganizeConfig) async throws -> JSONValue {
        try await client.send(.post, "/api/media_organize/save", query: nil, body: body)
    }

}
