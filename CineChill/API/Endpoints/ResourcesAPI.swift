// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `Resources` 分组，共 16 个接口。
public struct ResourcesAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Apply
    /// `POST /api/apply`
    @discardableResult
    public func apply(_ body: PreviewRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/apply", query: nil, body: body)
    }

    /// Create Suite
    /// `POST /api/create_suite`
    @discardableResult
    public func createSuite(_ body: SuiteBackupRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/create_suite", query: nil, body: body)
    }

    /// Delete Font
    /// `POST /api/delete_font`
    @discardableResult
    public func deleteFont(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/delete_font", query: nil, body: body)
    }

    /// Delete Suite
    /// `POST /api/delete_suite`
    @discardableResult
    public func deleteSuite(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/delete_suite", query: nil, body: body)
    }

    /// Delete Template
    /// `POST /api/delete_template`
    @discardableResult
    public func deleteTemplate(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/delete_template", query: nil, body: body)
    }

    /// Get Fonts
    /// `GET /api/fonts`
    @discardableResult
    public func getFonts() async throws -> JSONValue {
        try await client.send(.get, "/api/fonts", query: nil)
    }

    /// Get Suite Content
    /// `POST /api/get_suite_content`
    @discardableResult
    public func getSuiteContent(_ body: SuiteContentRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/get_suite_content", query: nil, body: body)
    }

    /// Get Layouts
    /// `GET /api/layouts`
    @discardableResult
    public func getLayouts() async throws -> JSONValue {
        try await client.send(.get, "/api/layouts", query: nil)
    }

    /// List Suites
    /// `GET /api/list_suites`
    @discardableResult
    public func listSuites() async throws -> JSONValue {
        try await client.send(.get, "/api/list_suites", query: nil)
    }

    /// Preview
    /// `POST /api/preview`
    @discardableResult
    public func preview(_ body: PreviewRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/preview", query: nil, body: body)
    }

    /// Restore Suite
    /// `POST /api/restore_suite`
    @discardableResult
    public func restoreSuite(_ body: SuiteRestoreRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/restore_suite", query: nil, body: body)
    }

    /// Save Template
    /// `POST /api/save_template`
    @discardableResult
    public func saveTemplate(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/save_template", query: nil, body: body)
    }

    /// Save Translations
    /// `POST /api/save_translations`
    @discardableResult
    public func saveTranslations(_ body: JSONValue) async throws -> JSONValue {
        try await client.send(.post, "/api/save_translations", query: nil, body: body)
    }

    /// Get Templates V2
    /// `GET /api/templates_v2`
    @discardableResult
    public func getTemplatesV2() async throws -> JSONValue {
        try await client.send(.get, "/api/templates_v2", query: nil)
    }

    /// Get Translations
    /// `GET /api/translations`
    @discardableResult
    public func getTranslations() async throws -> JSONValue {
        try await client.send(.get, "/api/translations", query: nil)
    }

    /// Upload Font
    /// `POST /api/upload_font`
    public func uploadFont(fileData: Data, filename: String, mimeType: String = "application/octet-stream") async throws -> JSONValue {
        try await client.upload(path: "/api/upload_font", fieldName: "file", fileData: fileData, filename: filename, mimeType: mimeType, query: nil)
    }

}
