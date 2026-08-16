import Foundation

/// Web v1.0.0.73 已使用、但 v1.0.0.43 OpenAPI 尚未声明的接口。
/// 单独维护在扩展中，避免修改自动生成文件并在下次重新生成时被覆盖。
public extension MoviePilotAPI {
    @discardableResult
    func getSites() async throws -> JSONValue {
        try await client.send(.get, "/api/moviepilot/sites", query: nil)
    }

    @discardableResult
    func getSiteMonitorConfig() async throws -> JSONValue {
        try await client.send(.get, "/api/moviepilot/site-monitor/config", query: nil)
    }

    @discardableResult
    func updateSiteMonitorConfig(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.put, "/api/moviepilot/site-monitor/config", query: nil, body: body)
    }

    @discardableResult
    func getSiteMonitorStatus() async throws -> JSONValue {
        try await client.send(.get, "/api/moviepilot/site-monitor/status", query: nil)
    }

    @discardableResult
    func runSiteMonitor(siteIDs: [JSONValue] = []) async throws -> JSONValue {
        try await client.send(
            .post,
            "/api/moviepilot/site-monitor/run",
            query: nil,
            body: JSONValue.object(["site_ids": .array(siteIDs)]))
    }

    @discardableResult
    func checkSitesHealth(siteIDs: [JSONValue] = []) async throws -> JSONValue {
        try await client.send(
            .post,
            "/api/moviepilot/sites/health-check",
            query: nil,
            body: JSONValue.object(["site_ids": .array(siteIDs)]),
            timeout: 300)
    }

    @discardableResult
    func clearSubscriptionRecords(workspace: String,
                                  clearAll: Bool = false,
                                  tmdbID: String? = nil,
                                  typeName: String = "movie") async throws -> JSONValue {
        try await client.send(
            .delete,
            "/api/moviepilot/subscribe/records",
            query: [
                "workspace": Query.value(workspace),
                "clear_all": Query.value(clearAll),
                "tmdbid": clearAll ? nil : Query.value(tmdbID),
                "type_name": Query.value(typeName),
            ])
    }
}

public extension SubscriptionsAPI {
    @discardableResult
    func getEpisodeProgress(items: [JSONValue]) async throws -> JSONValue {
        try await client.send(
            .post,
            "/api/subscriptions/episode_progress",
            query: nil,
            body: JSONValue.object(["items": .array(items)]))
    }
}

public extension Drive115UploadAPI {
    /// v73 上传任务增加了整种清理字段，使用原始 JSON 可保留后续新增字段。
    @discardableResult
    func saveTaskPreservingFields(taskID: String?, body: JSONValue) async throws -> JSONValue {
        if let taskID, !taskID.isEmpty {
            return try await client.send(
                .post,
                "/api/drive115_upload/tasks/\(Path.escape(taskID))",
                query: nil,
                body: body)
        }
        return try await client.send(.post, "/api/drive115_upload/tasks", query: nil, body: body)
    }

    @discardableResult
    func cancelFile(taskID: String, jobID: String) async throws -> JSONValue {
        try await client.send(
            .post,
            "/api/drive115_upload/tasks/\(Path.escape(taskID))/jobs/\(Path.escape(jobID))/cancel",
            query: nil,
            body: JSONValue.object([:]))
    }
}

public extension MediaOrganizeAPI {
    /// 原样保存服务端返回的配置，防止旧版强类型模型丢弃 Web v73 新增字段。
    @discardableResult
    func saveConfigPreservingFields(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/media_organize/save", query: nil, body: body)
    }
}
