// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `OrganizeHistory` 分组，共 10 个接口。
public struct OrganizeHistoryAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Search Organize History Media
    /// `GET /api/organize-history/media-search`
    @discardableResult
    public func searchOrganizeHistoryMedia(query: String, mediaType: String? = nil, year: String? = nil, limit: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/organize-history/media-search", query: ["query": Query.value(query), "media_type": Query.value(mediaType), "year": Query.value(year), "limit": Query.value(limit)])
    }

    /// Get Organize History
    /// `GET /api/organize-history/records`
    @discardableResult
    public func getOrganizeHistory(category: String? = nil, keyword: String? = nil, limit: Int? = nil, page: Int? = nil, pageSize: Int? = nil, days: Int? = nil, compact: Bool? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/organize-history/records", query: ["category": Query.value(category), "keyword": Query.value(keyword), "limit": Query.value(limit), "page": Query.value(page), "page_size": Query.value(pageSize), "days": Query.value(days), "compact": Query.value(compact)])
    }

    /// Ai Redo Organize History Records
    /// `POST /api/organize-history/records/ai-redo`
    @discardableResult
    public func aiRedoOrganizeHistoryRecords(_ body: RedoOrganizeHistoryPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/organize-history/records/ai-redo", query: nil, body: body)
    }

    /// Clear Organize History Records
    /// `POST /api/organize-history/records/clear`
    @discardableResult
    public func clearOrganizeHistoryRecords(_ body: ClearOrganizeHistoryPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/organize-history/records/clear", query: nil, body: body)
    }

    /// Delete Organize History Records
    /// `POST /api/organize-history/records/delete`
    @discardableResult
    public func deleteOrganizeHistoryRecords(_ body: DeleteOrganizeHistoryPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/organize-history/records/delete", query: nil, body: body)
    }

    /// Redo Organize History Records
    /// `POST /api/organize-history/records/redo`
    @discardableResult
    public func redoOrganizeHistoryRecords(_ body: RedoOrganizeHistoryPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/organize-history/records/redo", query: nil, body: body)
    }

    /// Ai Redo Organize History Record
    /// `POST /api/organize-history/records/{record_id}/ai-redo`
    @discardableResult
    public func aiRedoOrganizeHistoryRecord(recordId: String, _ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/organize-history/records/\(Path.escape(recordId))/ai-redo", query: nil, body: body)
    }

    /// Redo Organize History Record
    /// `POST /api/organize-history/records/{record_id}/redo`
    @discardableResult
    public func redoOrganizeHistoryRecord(recordId: String, _ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/organize-history/records/\(Path.escape(recordId))/redo", query: nil, body: body)
    }

    /// Get Organize History Summary
    /// `GET /api/organize-history/summary`
    @discardableResult
    public func getOrganizeHistorySummary(days: Int? = nil, keyword: String? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/organize-history/summary", query: ["days": Query.value(days), "keyword": Query.value(keyword)])
    }

    /// Get Organize History Episode Groups
    /// `GET /api/organize-history/tmdb/{tmdb_id}/episode-groups`
    @discardableResult
    public func getOrganizeHistoryEpisodeGroups(tmdbId: Int) async throws -> JSONValue {
        try await client.send(.get, "/api/organize-history/tmdb/\(Path.escape(String(tmdbId)))/episode-groups", query: nil)
    }

}
