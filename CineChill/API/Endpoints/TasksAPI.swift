// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `Tasks` 分组，共 13 个接口。
public struct TasksAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Clear System Logs
    /// 清空系统日志
    /// `POST /api/clear_system_logs`
    @discardableResult
    public func clearSystemLogs() async throws -> JSONValue {
        try await client.send(.post, "/api/clear_system_logs", query: nil)
    }

    /// Clear Task Progress
    /// `POST /api/clear_task_progress`
    @discardableResult
    public func clearTaskProgress(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/clear_task_progress", query: nil, body: body)
    }

    /// Create Task Endpoint
    /// `POST /api/create_task`
    @discardableResult
    public func createTaskEndpoint(_ body: CreateTaskRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/create_task", query: nil, body: body)
    }

    /// Delete Task Endpoint
    /// `POST /api/delete_task`
    @discardableResult
    public func deleteTaskEndpoint(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/delete_task", query: nil, body: body)
    }

    /// Get Progress
    /// `GET /api/progress`
    @discardableResult
    public func getProgress() async throws -> JSONValue {
        try await client.send(.get, "/api/progress", query: nil)
    }

    /// Run Saved Task Endpoint
    /// `POST /api/run_saved_task`
    @discardableResult
    public func runSavedTaskEndpoint(_ body: RunSavedTaskRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/run_saved_task", query: nil, body: body)
    }

    /// Run Task Batch
    /// `POST /api/run_task`
    @discardableResult
    public func runTaskBatch(_ body: RunTaskRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/run_task", query: nil, body: body)
    }

    /// Stop Task
    /// `POST /api/stop_task`
    @discardableResult
    public func stopTask(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/stop_task", query: nil, body: body)
    }

    /// Get System Logs
    /// `GET /api/system_logs`
    @discardableResult
    public func getSystemLogs(level: String? = nil, keyword: String? = nil, category: String? = nil, limit: Int? = nil, hideDebug: Bool? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/system_logs", query: ["level": Query.value(level), "keyword": Query.value(keyword), "category": Query.value(category), "limit": Query.value(limit), "hide_debug": Query.value(hideDebug)])
    }

    /// Stream System Logs
    /// `GET /api/system_logs/stream`
    public func streamSystemLogsRequest(level: String? = nil, keyword: String? = nil, category: String? = nil, lastEventId: Int? = nil, hideDebug: Bool? = nil) throws -> URLRequest {
        try client.streamRequest(method: .get, path: "/api/system_logs/stream", query: ["level": Query.value(level), "keyword": Query.value(keyword), "category": Query.value(category), "last_event_id": Query.value(lastEventId), "hide_debug": Query.value(hideDebug)])
    }

    /// Get Tasks
    /// `GET /api/tasks`
    @discardableResult
    public func getTasks() async throws -> JSONValue {
        try await client.send(.get, "/api/tasks", query: nil)
    }

    /// Toggle Task Endpoint
    /// `POST /api/toggle_task`
    @discardableResult
    public func toggleTaskEndpoint(_ body: ToggleTaskRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/toggle_task", query: nil, body: body)
    }

    /// Update Task Endpoint
    /// `POST /api/update_task`
    @discardableResult
    public func updateTaskEndpoint(_ body: UpdateTaskRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/update_task", query: nil, body: body)
    }

}
