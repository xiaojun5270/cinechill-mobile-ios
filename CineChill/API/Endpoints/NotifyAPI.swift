// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `Notify` 分组，共 21 个接口。
public struct NotifyAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// Get Notification Channels
    /// 获取所有通知渠道及其状态
    /// `GET /api/notify/channels`
    @discardableResult
    public func getNotificationChannels() async throws -> JSONValue {
        try await client.send(.get, "/api/notify/channels", query: nil)
    }

    /// Get Notification Default Templates
    /// 获取后端当前版本的默认通知模板。
    /// `GET /api/notify/default-templates`
    @discardableResult
    public func getNotificationDefaultTemplates() async throws -> JSONValue {
        try await client.send(.get, "/api/notify/default-templates", query: nil)
    }

    /// Get Notification Types
    /// 获取可用的通知类型列表
    /// `GET /api/notify/types`
    @discardableResult
    public func getNotificationTypes() async throws -> JSONValue {
        try await client.send(.get, "/api/notify/types", query: nil)
    }

    /// Get Telegram Avatar
    /// 读取已缓存的 Telegram 群组/频道头像
    /// `GET /api/telegram-notify/avatar/{filename}`
    public func getTelegramAvatarURL(filename: String) throws -> URL {
        try client.url(path: "/api/telegram-notify/avatar/\(Path.escape(filename))", query: nil)
    }

    /// Get Telegram Notify Config
    /// 获取 Telegram 通知配置
    /// `GET /api/telegram-notify/config`
    @discardableResult
    public func getTelegramNotifyConfig() async throws -> JSONValue {
        try await client.send(.get, "/api/telegram-notify/config", query: nil)
    }

    /// Save Telegram Notify Config
    /// 保存 Telegram 账号监听配置
    /// `POST /api/telegram-notify/config`
    @discardableResult
    public func saveTelegramNotifyConfig(_ body: TelegramNotifyConfigModel) async throws -> JSONValue {
        try await client.send(.post, "/api/telegram-notify/config", query: nil, body: body)
    }

    /// List Telegram Dialogs
    /// 获取 Telegram 群组与频道列表
    /// `GET /api/telegram-notify/dialogs`
    @discardableResult
    public func listTelegramDialogs() async throws -> JSONValue {
        try await client.send(.get, "/api/telegram-notify/dialogs", query: nil)
    }

    /// Save Telegram Dialogs
    /// 保存 Telegram 监听目标
    /// `POST /api/telegram-notify/dialogs`
    @discardableResult
    public func saveTelegramDialogs(_ body: TelegramDialogsRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/telegram-notify/dialogs", query: nil, body: body)
    }

    /// Logout Telegram
    /// 退出 Telegram 账号登录并清理本地 session
    /// `POST /api/telegram-notify/logout`
    @discardableResult
    public func logoutTelegram() async throws -> JSONValue {
        try await client.send(.post, "/api/telegram-notify/logout", query: nil)
    }

    /// Send Telegram Test Message
    /// 发送 Telegram 测试消息
    /// `POST /api/telegram-notify/send`
    @discardableResult
    public func sendTelegramTestMessage(message: String? = nil) async throws -> JSONValue {
        try await client.send(.post, "/api/telegram-notify/send", query: ["message": Query.value(message)])
    }

    /// Send Telegram Login Code
    /// 发送 Telegram 登录验证码
    /// `POST /api/telegram-notify/send-code`
    @discardableResult
    public func sendTelegramLoginCode(_ body: TelegramSendCodeRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/telegram-notify/send-code", query: nil, body: body)
    }

    /// Sign In Telegram
    /// 使用验证码/两步验证密码登录 Telegram
    /// `POST /api/telegram-notify/sign-in`
    @discardableResult
    public func signInTelegram(_ body: TelegramSignInRequest) async throws -> JSONValue {
        try await client.send(.post, "/api/telegram-notify/sign-in", query: nil, body: body)
    }

    /// Get Telegram Status
    /// 获取 Telegram 账号登录与监听状态
    /// `GET /api/telegram-notify/status`
    @discardableResult
    public func getTelegramStatus() async throws -> JSONValue {
        try await client.send(.get, "/api/telegram-notify/status", query: nil)
    }

    /// Test Telegram Notify
    /// 测试 Telegram 通知连接
    /// `POST /api/telegram-notify/test`
    @discardableResult
    public func testTelegramNotify() async throws -> JSONValue {
        try await client.send(.post, "/api/telegram-notify/test", query: nil)
    }

    /// Wechat Callback Verify
    /// 企业微信回调 URL 验证
    /// 企业微信会发送 GET 请求来验证 URL 有效性
    /// `GET /api/wechat-notify/callback`
    @discardableResult
    public func wechatCallbackVerify(msgSignature: String? = nil, timestamp: String? = nil, nonce: String? = nil, echostr: String? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/wechat-notify/callback", query: ["msg_signature": Query.value(msgSignature), "timestamp": Query.value(timestamp), "nonce": Query.value(nonce), "echostr": Query.value(echostr)])
    }

    /// Wechat Callback Message
    /// 接收企业微信推送的消息
    /// 流程：读取 body → 解密(如需) → 解析 XML → 提取 115 链接 → 转存 → 通知
    /// `POST /api/wechat-notify/callback`
    @discardableResult
    public func wechatCallbackMessage() async throws -> JSONValue {
        try await client.send(.post, "/api/wechat-notify/callback", query: nil)
    }

    /// Get Wechat Notify Config
    /// 获取微信通知配置
    /// `GET /api/wechat-notify/config`
    @discardableResult
    public func getWechatNotifyConfig() async throws -> JSONValue {
        try await client.send(.get, "/api/wechat-notify/config", query: nil)
    }

    /// Save Wechat Notify Config
    /// 保存微信通知配置
    /// `POST /api/wechat-notify/config`
    @discardableResult
    public func saveWechatNotifyConfig(_ body: WechatNotifyConfigModel) async throws -> JSONValue {
        try await client.send(.post, "/api/wechat-notify/config", query: nil, body: body)
    }

    /// Send Wechat Test Message
    /// 发送测试消息
    /// `POST /api/wechat-notify/send`
    @discardableResult
    public func sendWechatTestMessage(message: String? = nil) async throws -> JSONValue {
        try await client.send(.post, "/api/wechat-notify/send", query: ["message": Query.value(message)])
    }

    /// Test Wechat Notify
    /// 测试微信通知连接
    /// `POST /api/wechat-notify/test`
    @discardableResult
    public func testWechatNotify() async throws -> JSONValue {
        try await client.send(.post, "/api/wechat-notify/test", query: nil)
    }

    /// Get Wechat Notification Types
    /// 获取可用的通知类型列表（兼容旧接口）
    /// `GET /api/wechat-notify/types`
    @discardableResult
    public func getWechatNotificationTypes() async throws -> JSONValue {
        try await client.send(.get, "/api/wechat-notify/types", query: nil)
    }

}
