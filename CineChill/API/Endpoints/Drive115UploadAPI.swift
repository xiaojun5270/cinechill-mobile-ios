// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `Drive115Upload` 分组，共 21 个接口。
public struct Drive115UploadAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Browse 115
    /// `POST /api/drive115_upload/browse115`
    @discardableResult
    public func browse115(_ body: Browse115Payload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/browse115", query: nil, body: body)
    }

    /// Browse Local
    /// `POST /api/drive115_upload/browse_local`
    @discardableResult
    public func browseLocal(_ body: LocalBrowsePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/browse_local", query: nil, body: body)
    }

    /// Browse Cloud 115
    /// `POST /api/drive115_upload/cloud/browse`
    @discardableResult
    public func browseCloud115(_ body: CloudBrowsePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/cloud/browse", query: nil, body: body)
    }

    /// Get Cloud Rapid Job
    /// `GET /api/drive115_upload/cloud/jobs/{job_id}`
    @discardableResult
    public func getCloudRapidJob(jobId: String) async throws -> JSONValue {
        try await client.send(.get, "/api/drive115_upload/cloud/jobs/\(Path.escape(jobId))", query: nil)
    }

    /// Cancel Cloud Rapid Job
    /// `POST /api/drive115_upload/cloud/jobs/{job_id}/cancel`
    @discardableResult
    public func cancelCloudRapidJob(jobId: String) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/cloud/jobs/\(Path.escape(jobId))/cancel", query: nil)
    }

    /// Rapid Transfer Cloud 115
    /// `POST /api/drive115_upload/cloud/rapid_transfer`
    @discardableResult
    public func rapidTransferCloud115(_ body: CloudRapidPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/cloud/rapid_transfer", query: nil, body: body)
    }

    /// Clear History Records
    /// `POST /api/drive115_upload/history/clear`
    @discardableResult
    public func clearHistoryRecords() async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/history/clear", query: nil)
    }

    /// Delete History Record
    /// `POST /api/drive115_upload/history/delete`
    @discardableResult
    public func deleteHistoryRecord(_ body: HistoryRecordPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/history/delete", query: nil, body: body)
    }

    /// Get Status
    /// `GET /api/drive115_upload/status`
    @discardableResult
    public func getStatus() async throws -> JSONValue {
        try await client.send(.get, "/api/drive115_upload/status", query: nil)
    }

    /// Get Tasks
    /// `GET /api/drive115_upload/tasks`
    @discardableResult
    public func getTasks() async throws -> JSONValue {
        try await client.send(.get, "/api/drive115_upload/tasks", query: nil)
    }

    /// Create Task
    /// `POST /api/drive115_upload/tasks`
    @discardableResult
    public func createTask(_ body: UploadTaskPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/tasks", query: nil, body: body)
    }

    /// Update Task
    /// `POST /api/drive115_upload/tasks/{task_id}`
    @discardableResult
    public func updateTask(taskId: String, _ body: UploadTaskPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/tasks/\(Path.escape(taskId))", query: nil, body: body)
    }

    /// Delete Task
    /// `DELETE /api/drive115_upload/tasks/{task_id}`
    @discardableResult
    public func deleteTask(taskId: String) async throws -> JSONValue {
        try await client.send(.delete, "/api/drive115_upload/tasks/\(Path.escape(taskId))", query: nil)
    }

    /// Clear History
    /// `POST /api/drive115_upload/tasks/{task_id}/clear_history`
    @discardableResult
    public func clearHistory(taskId: String) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/tasks/\(Path.escape(taskId))/clear_history", query: nil)
    }

    /// Retry File
    /// `POST /api/drive115_upload/tasks/{task_id}/retry`
    @discardableResult
    public func retryFile(taskId: String, _ body: RetryPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/tasks/\(Path.escape(taskId))/retry", query: nil, body: body)
    }

    /// Scan Task
    /// `POST /api/drive115_upload/tasks/{task_id}/scan`
    @discardableResult
    public func scanTask(taskId: String, _ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/tasks/\(Path.escape(taskId))/scan", query: nil, body: body)
    }

    /// Get Task Status
    /// `GET /api/drive115_upload/tasks/{task_id}/status`
    @discardableResult
    public func getTaskStatus(taskId: String) async throws -> JSONValue {
        try await client.send(.get, "/api/drive115_upload/tasks/\(Path.escape(taskId))/status", query: nil)
    }

    /// Stop Task
    /// `POST /api/drive115_upload/tasks/{task_id}/stop`
    @discardableResult
    public func stopTask(taskId: String) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/tasks/\(Path.escape(taskId))/stop", query: nil)
    }

    /// Toggle Task
    /// `POST /api/drive115_upload/tasks/{task_id}/toggle`
    @discardableResult
    public func toggleTask(taskId: String, _ body: TogglePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/tasks/\(Path.escape(taskId))/toggle", query: nil, body: body)
    }

    /// Get Thread Settings
    /// `GET /api/drive115_upload/thread_settings`
    @discardableResult
    public func getThreadSettings() async throws -> JSONValue {
        try await client.send(.get, "/api/drive115_upload/thread_settings", query: nil)
    }

    /// Update Thread Settings
    /// `POST /api/drive115_upload/thread_settings`
    @discardableResult
    public func updateThreadSettings(_ body: UploadThreadSettingsPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/drive115_upload/thread_settings", query: nil, body: body)
    }

}
