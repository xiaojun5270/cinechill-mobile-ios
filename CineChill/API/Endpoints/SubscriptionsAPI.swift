// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `Subscriptions` 分组，共 7 个接口。
public struct SubscriptionsAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Get Subscription Activity
    /// `GET /api/subscriptions/activity`
    @discardableResult
    public func getSubscriptionActivity(subscriptionIds: String? = nil, tmdbId: String? = nil, mediaType: String? = nil, title: String? = nil, limit: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/subscriptions/activity", query: ["subscription_ids": Query.value(subscriptionIds), "tmdb_id": Query.value(tmdbId), "media_type": Query.value(mediaType), "title": Query.value(title), "limit": Query.value(limit)])
    }

    /// List Subscription Events
    /// `GET /api/subscriptions/events`
    @discardableResult
    public func listSubscriptionEvents(limit: Int? = nil, eventType: String? = nil, subscriptionIds: String? = nil, tmdbId: String? = nil, mediaType: String? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/subscriptions/events", query: ["limit": Query.value(limit), "event_type": Query.value(eventType), "subscription_ids": Query.value(subscriptionIds), "tmdb_id": Query.value(tmdbId), "media_type": Query.value(mediaType)])
    }

    /// List Subscription Rss Sources
    /// `GET /api/subscriptions/rss_sources`
    @discardableResult
    public func listSubscriptionRssSources() async throws -> JSONValue {
        try await client.send(.get, "/api/subscriptions/rss_sources", query: nil)
    }

    /// Create Subscription Rss Source
    /// `POST /api/subscriptions/rss_sources`
    @discardableResult
    public func createSubscriptionRssSource(_ body: RssSourcePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/subscriptions/rss_sources", query: nil, body: body)
    }

    /// Patch Subscription Rss Source
    /// `PATCH /api/subscriptions/rss_sources/{source_id}`
    @discardableResult
    public func patchSubscriptionRssSource(sourceId: String, _ body: RssSourcePatchPayload) async throws -> JSONValue {
        try await client.send(.patch, "/api/subscriptions/rss_sources/\(Path.escape(sourceId))", query: nil, body: body)
    }

    /// Delete Subscription Rss Source
    /// `DELETE /api/subscriptions/rss_sources/{source_id}`
    @discardableResult
    public func deleteSubscriptionRssSource(sourceId: String) async throws -> JSONValue {
        try await client.send(.delete, "/api/subscriptions/rss_sources/\(Path.escape(sourceId))", query: nil)
    }

    /// Sync Subscription Rss Source
    /// `POST /api/subscriptions/rss_sources/{source_id}/sync`
    @discardableResult
    public func syncSubscriptionRssSource(sourceId: String) async throws -> JSONValue {
        try await client.send(.post, "/api/subscriptions/rss_sources/\(Path.escape(sourceId))/sync", query: nil)
    }

}
