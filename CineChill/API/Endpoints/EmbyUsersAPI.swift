// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `EmbyUsers` 分组，共 10 个接口。
public struct EmbyUsersAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// List Emby Users
    /// `GET /api/emby/users`
    @discardableResult
    public func listEmbyUsers() async throws -> JSONValue {
        try await client.send(.get, "/api/emby/users", query: nil)
    }

    /// Create Emby User
    /// `POST /api/emby/users/create`
    @discardableResult
    public func createEmbyUser(_ body: EmbyUserCreatePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/emby/users/create", query: nil, body: body)
    }

    /// Get Emby User
    /// `GET /api/emby/users/{user_id}`
    @discardableResult
    public func getEmbyUser(userId: String) async throws -> JSONValue {
        try await client.send(.get, "/api/emby/users/\(Path.escape(userId))", query: nil)
    }

    /// Delete Emby User
    /// `DELETE /api/emby/users/{user_id}`
    @discardableResult
    public func deleteEmbyUser(userId: String) async throws -> JSONValue {
        try await client.send(.delete, "/api/emby/users/\(Path.escape(userId))", query: nil)
    }

    /// Upload Emby User Avatar
    /// `POST /api/emby/users/{user_id}/avatar`
    public func uploadEmbyUserAvatar(userId: String, fileData: Data, filename: String, mimeType: String = "application/octet-stream") async throws -> JSONValue {
        try await client.upload(path: "/api/emby/users/\(Path.escape(userId))/avatar", fieldName: "file", fileData: fileData, filename: filename, mimeType: mimeType, query: nil)
    }

    /// Get Emby User Avatar
    /// `GET /api/emby/users/{user_id}/avatar`
    public func getEmbyUserAvatarURL(userId: String, tag: String? = nil) throws -> URL {
        try client.url(path: "/api/emby/users/\(Path.escape(userId))/avatar", query: ["tag": Query.value(tag)])
    }

    /// Bind Emby User
    /// `POST /api/emby/users/{user_id}/bind`
    @discardableResult
    public func bindEmbyUser(userId: String) async throws -> JSONValue {
        try await client.send(.post, "/api/emby/users/\(Path.escape(userId))/bind", query: nil)
    }

    /// Set Emby User Disabled
    /// `POST /api/emby/users/{user_id}/disabled`
    @discardableResult
    public func setEmbyUserDisabled(userId: String, _ body: EmbyUserDisabledPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/emby/users/\(Path.escape(userId))/disabled", query: nil, body: body)
    }

    /// Reset Emby User Password
    /// `POST /api/emby/users/{user_id}/password`
    @discardableResult
    public func resetEmbyUserPassword(userId: String, _ body: EmbyUserPasswordPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/emby/users/\(Path.escape(userId))/password", query: nil, body: body)
    }

    /// Update Emby User
    /// `POST /api/emby/users/{user_id}/update`
    @discardableResult
    public func updateEmbyUser(userId: String, _ body: EmbyUserUpdatePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/emby/users/\(Path.escape(userId))/update", query: nil, body: body)
    }

}
