// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `Webhook` 分组，共 4 个接口。
public struct WebhookAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Emby Webhook Trigger
    /// `POST /api/webhook`
    @discardableResult
    public func embyWebhookTrigger() async throws -> JSONValue {
        try await client.send(.post, "/api/webhook", query: nil)
    }

    /// Get Webhook Config
    /// `GET /api/webhook/config`
    @discardableResult
    public func getWebhookConfig() async throws -> JSONValue {
        try await client.send(.get, "/api/webhook/config", query: nil)
    }

    /// Save Webhook Config
    /// `POST /api/webhook/config`
    @discardableResult
    public func saveWebhookConfig(_ body: WebhookConfigModel) async throws -> JSONValue {
        try await client.send(.post, "/api/webhook/config", query: nil, body: body)
    }

    /// Get Webhook Queue
    /// `GET /api/webhook/queue`
    @discardableResult
    public func getWebhookQueue() async throws -> JSONValue {
        try await client.send(.get, "/api/webhook/queue", query: nil)
    }

}
