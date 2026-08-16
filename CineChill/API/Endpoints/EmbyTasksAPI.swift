// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `EmbyTasks` 分组，共 5 个接口。
public struct EmbyTasksAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// List Emby Tasks
    /// `GET /api/emby_tasks`
    @discardableResult
    public func listEmbyTasks() async throws -> JSONValue {
        try await client.send(.get, "/api/emby_tasks", query: nil)
    }

    /// Run Emby Task
    /// `POST /api/emby_tasks/{task_id}/run`
    @discardableResult
    public func runEmbyTask(taskId: String) async throws -> JSONValue {
        try await client.send(.post, "/api/emby_tasks/\(Path.escape(taskId))/run", query: nil)
    }

    /// Stop Emby Task
    /// `POST /api/emby_tasks/{task_id}/stop`
    @discardableResult
    public func stopEmbyTask(taskId: String) async throws -> JSONValue {
        try await client.send(.post, "/api/emby_tasks/\(Path.escape(taskId))/stop", query: nil)
    }

    /// Get Emby Task Triggers
    /// `GET /api/emby_tasks/{task_id}/triggers`
    @discardableResult
    public func getEmbyTaskTriggers(taskId: String) async throws -> JSONValue {
        try await client.send(.get, "/api/emby_tasks/\(Path.escape(taskId))/triggers", query: nil)
    }

    /// Update Emby Task Triggers
    /// `POST /api/emby_tasks/{task_id}/triggers`
    @discardableResult
    public func updateEmbyTaskTriggers(taskId: String, _ body: EmbyTaskTriggersPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/emby_tasks/\(Path.escape(taskId))/triggers", query: nil, body: body)
    }

}
