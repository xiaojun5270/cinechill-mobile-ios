// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `AIEpisodeResolver` 分组，共 17 个接口。
public struct AIAssistantAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Read Ai Assistant Audit
    /// `GET /api/ai-episode-resolver/audit`
    @discardableResult
    public func readAiAssistantAudit(limit: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/ai-episode-resolver/audit", query: ["limit": Query.value(limit)])
    }

    /// Read Ai Episode Resolver Config
    /// `GET /api/ai-episode-resolver/config`
    @discardableResult
    public func readAiEpisodeResolverConfig() async throws -> JSONValue {
        try await client.send(.get, "/api/ai-episode-resolver/config", query: nil)
    }

    /// Update Ai Episode Resolver Config
    /// `POST /api/ai-episode-resolver/config`
    @discardableResult
    public func updateAiEpisodeResolverConfig(_ body: AIEpisodeResolverConfigPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/ai-episode-resolver/config", query: nil, body: body)
    }

    /// Read Ai Assistant Context
    /// `GET /api/ai-episode-resolver/context`
    @discardableResult
    public func readAiAssistantContext() async throws -> JSONValue {
        try await client.send(.get, "/api/ai-episode-resolver/context", query: nil)
    }

    /// Read Ai Assistant Memory
    /// `GET /api/ai-episode-resolver/memory`
    @discardableResult
    public func readAiAssistantMemory() async throws -> JSONValue {
        try await client.send(.get, "/api/ai-episode-resolver/memory", query: nil)
    }

    /// Read Ai Assistant Memory Profile
    /// `GET /api/ai-episode-resolver/memory/profile`
    @discardableResult
    public func readAiAssistantMemoryProfile() async throws -> JSONValue {
        try await client.send(.get, "/api/ai-episode-resolver/memory/profile", query: nil)
    }

    /// Update Ai Assistant Memory Profile
    /// `POST /api/ai-episode-resolver/memory/profile`
    @discardableResult
    public func updateAiAssistantMemoryProfile(_ body: AIAssistantGlobalProfilePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/ai-episode-resolver/memory/profile", query: nil, body: body)
    }

    /// List Ai Episode Resolver Models
    /// `POST /api/ai-episode-resolver/models`
    @discardableResult
    public func listAiEpisodeResolverModels(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/ai-episode-resolver/models", query: nil, body: body)
    }

    /// Read Ai Assistant Reminders
    /// `GET /api/ai-episode-resolver/reminders`
    @discardableResult
    public func readAiAssistantReminders(status: String? = nil, limit: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/ai-episode-resolver/reminders", query: ["status": Query.value(status), "limit": Query.value(limit)])
    }

    /// Create Ai Assistant Reminder
    /// `POST /api/ai-episode-resolver/reminders`
    @discardableResult
    public func createAiAssistantReminder(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/ai-episode-resolver/reminders", query: nil, body: body)
    }

    /// Update Ai Assistant Reminder
    /// `POST /api/ai-episode-resolver/reminders/{reminder_id}`
    @discardableResult
    public func updateAiAssistantReminder(reminderId: String, _ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/ai-episode-resolver/reminders/\(Path.escape(reminderId))", query: nil, body: body)
    }

    /// Delete Ai Assistant Reminder
    /// `DELETE /api/ai-episode-resolver/reminders/{reminder_id}`
    @discardableResult
    public func deleteAiAssistantReminder(reminderId: String) async throws -> JSONValue {
        try await client.send(.delete, "/api/ai-episode-resolver/reminders/\(Path.escape(reminderId))", query: nil)
    }

    /// Cancel Ai Assistant Reminder
    /// `POST /api/ai-episode-resolver/reminders/{reminder_id}/cancel`
    @discardableResult
    public func cancelAiAssistantReminder(reminderId: String) async throws -> JSONValue {
        try await client.send(.post, "/api/ai-episode-resolver/reminders/\(Path.escape(reminderId))/cancel", query: nil)
    }

    /// Read Ai Assistant Runtime
    /// `GET /api/ai-episode-resolver/runtime`
    @discardableResult
    public func readAiAssistantRuntime() async throws -> JSONValue {
        try await client.send(.get, "/api/ai-episode-resolver/runtime", query: nil)
    }

    /// Test Ai Episode Resolver
    /// `POST /api/ai-episode-resolver/test`
    @discardableResult
    public func testAiEpisodeResolver(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/ai-episode-resolver/test", query: nil, body: body)
    }

    /// Read Ai Assistant Tool Permissions
    /// `GET /api/ai-episode-resolver/tool-permissions`
    @discardableResult
    public func readAiAssistantToolPermissions() async throws -> JSONValue {
        try await client.send(.get, "/api/ai-episode-resolver/tool-permissions", query: nil)
    }

    /// Update Ai Assistant Tool Permissions
    /// `POST /api/ai-episode-resolver/tool-permissions`
    @discardableResult
    public func updateAiAssistantToolPermissions(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/ai-episode-resolver/tool-permissions", query: nil, body: body)
    }

}
