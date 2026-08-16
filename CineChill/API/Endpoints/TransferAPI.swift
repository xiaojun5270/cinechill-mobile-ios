// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `Transfer` 分组，共 3 个接口。
public struct TransferAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Get Transfer History
    /// 获取转存历史记录
    /// `GET /api/transfer/history`
    @discardableResult
    public func getTransferHistory() async throws -> JSONValue {
        try await client.send(.get, "/api/transfer/history", query: nil)
    }

    /// Clear Transfer History
    /// 清空转存历史记录
    /// `DELETE /api/transfer/history`
    @discardableResult
    public func clearTransferHistory() async throws -> JSONValue {
        try await client.send(.delete, "/api/transfer/history", query: nil)
    }

    /// Manual Transfer
    /// 手动转存 115 分享链接
    /// `POST /api/transfer/manual`
    @discardableResult
    public func manualTransfer(_ body: ManualTransferRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/transfer/manual", query: nil, body: body)
    }

}
