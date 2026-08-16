// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `config_302` 分组，共 11 个接口。
public struct Config302API: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Get 115 Qrcode Apps
    /// 返回当前 p115client 支持的扫码登录客户端。
    /// `GET /api/config_302/115_qrcode/apps`
    @discardableResult
    public func get115QrcodeApps() async throws -> JSONValue {
        try await client.send(.get, "/api/config_302/115_qrcode/apps", query: nil)
    }

    /// Get 115 Qrcode Result
    /// 获取 115 扫码登录结果并提取 Cookie
    /// `POST /api/config_302/115_qrcode/result`
    @discardableResult
    public func get115QrcodeResult(_ body: Result115QrPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/config_302/115_qrcode/result", query: nil, body: body)
    }

    /// Start 115 Qrcode
    /// 生成 115 扫码登录二维码
    /// `POST /api/config_302/115_qrcode/start`
    @discardableResult
    public func start115Qrcode(_ body: Start115QrPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/config_302/115_qrcode/start", query: nil, body: body)
    }

    /// Get 115 Qrcode Status
    /// 查询 115 扫码登录状态
    /// `POST /api/config_302/115_qrcode/status`
    @discardableResult
    public func get115QrcodeStatus(_ body: Status115QrPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/config_302/115_qrcode/status", query: nil, body: body)
    }

    /// Ensure Standard Topology Dirs
    /// 创建标准目录拓扑（第一步：仅目录创建）
    /// `POST /api/config_302/ensure_standard_topology_dirs`
    @discardableResult
    public func ensureStandardTopologyDirs(_ body: StandardTopologyDirsPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/config_302/ensure_standard_topology_dirs", query: nil, body: body)
    }

    /// Get Config 302
    /// 读取 302 配置
    /// `GET /api/config_302/get`
    @discardableResult
    public func getConfig302() async throws -> JSONValue {
        try await client.send(.get, "/api/config_302/get", query: nil)
    }

    /// Manual Cleanup
    /// 手动触发 115 清理任务（删除目录 + 清空回收站）
    /// `POST /api/config_302/manual_cleanup`
    @discardableResult
    public func manualCleanup(_ body: ManualCleanupPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/config_302/manual_cleanup", query: nil, body: body)
    }

    /// Manual Signin All
    /// 手动触发一次 115 批量签到
    /// `POST /api/config_302/manual_signin_all`
    @discardableResult
    public func manualSigninAll() async throws -> JSONValue {
        try await client.send(.post, "/api/config_302/manual_signin_all", query: nil)
    }

    /// Save Config 302
    /// 保存 302 配置
    /// `POST /api/config_302/save`
    @discardableResult
    public func saveConfig302(_ body: Config302Payload) async throws -> JSONValue {
        try await client.send(.post, "/api/config_302/save", query: nil, body: body)
    }

    /// Save Emby Config
    /// 仅保存 Emby 配置，不触发一条龙目录创建
    /// `POST /api/config_302/save_emby`
    @discardableResult
    public func saveEmbyConfig(_ body: SaveEmbyPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/config_302/save_emby", query: nil, body: body)
    }

    /// Test 115 Cookie
    /// 测试 115 Cookie 有效性
    /// `POST /api/config_302/test_115`
    @discardableResult
    public func test115Cookie(_ body: Test115Payload) async throws -> JSONValue {
        try await client.send(.post, "/api/config_302/test_115", query: nil, body: body)
    }

}
