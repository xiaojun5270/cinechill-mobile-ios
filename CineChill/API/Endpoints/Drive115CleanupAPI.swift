// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `Drive115Cleanup` 分组，共 7 个接口。
public struct Drive115CleanupAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Browse 115
    /// `POST /api/drive115_cleanup/browse115`
    @discardableResult
    public func browse115(_ body: Browse115Payload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_cleanup/browse115", query: nil, body: body)
    }

    /// Get Tasks
    /// `GET /api/drive115_cleanup/tasks`
    @discardableResult
    public func getTasks() async throws -> JSONValue {
        try await client.send(.get, "/api/drive115_cleanup/tasks", query: nil)
    }

    /// Create Task
    /// `POST /api/drive115_cleanup/tasks`
    @discardableResult
    public func createTask(_ body: CleanupTaskPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_cleanup/tasks", query: nil, body: body)
    }

    /// Update Task
    /// `POST /api/drive115_cleanup/tasks/{task_id}`
    @discardableResult
    public func updateTask(taskId: String, _ body: CleanupTaskPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_cleanup/tasks/\(Path.escape(taskId))", query: nil, body: body)
    }

    /// Delete Task
    /// `DELETE /api/drive115_cleanup/tasks/{task_id}`
    @discardableResult
    public func deleteTask(taskId: String) async throws -> JSONValue {
        try await client.send(.delete, "/api/drive115_cleanup/tasks/\(Path.escape(taskId))", query: nil)
    }

    /// Run Task
    /// `POST /api/drive115_cleanup/tasks/{task_id}/run`
    @discardableResult
    public func runTask(taskId: String) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_cleanup/tasks/\(Path.escape(taskId))/run", query: nil)
    }

    /// Toggle Task
    /// `POST /api/drive115_cleanup/tasks/{task_id}/toggle`
    @discardableResult
    public func toggleTask(taskId: String, _ body: TogglePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_cleanup/tasks/\(Path.escape(taskId))/toggle", query: nil, body: body)
    }

}
