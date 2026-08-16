// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `strm` 分组，共 6 个接口。
public struct StrmAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Get Strm Config
    /// 读取 STRM 配置
    /// `GET /api/strm/get`
    @discardableResult
    public func getStrmConfig() async throws -> JSONValue {
        try await client.send(.get, "/api/strm/get", query: nil)
    }

    /// Start Strm Metadata Backfill
    /// 只运行现有本地 STRM 库的 TMDb 元数据补齐，不生成 STRM。
    /// `POST /api/strm/metadata/start`
    @discardableResult
    public func startStrmMetadataBackfill(_ body: StrmStartPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/strm/metadata/start", query: nil, body: body)
    }

    /// Get Strm Progress
    /// 获取 STRM 相关的同步进度
    /// `GET /api/strm/progress`
    @discardableResult
    public func getStrmProgress() async throws -> JSONValue {
        try await client.send(.get, "/api/strm/progress", query: nil)
    }

    /// Save Strm Config
    /// 保存 STRM 配置
    /// `POST /api/strm/save`
    @discardableResult
    public func saveStrmConfig(_ body: StrmConfigPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/strm/save", query: nil, body: body)
    }

    /// Start Strm Sync
    /// 启动同步任务（全量或增量+监控）
    /// `POST /api/strm/start`
    @discardableResult
    public func startStrmSync(_ body: StrmStartPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/strm/start", query: nil, body: body)
    }

    /// Stop Strm Sync
    /// 取消同步/监控任务
    /// `POST /api/strm/stop`
    @discardableResult
    public func stopStrmSync(_ body: StrmStopPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/strm/stop", query: nil, body: body)
    }

}
