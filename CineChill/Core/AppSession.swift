import Foundation
import SwiftUI

/// 全局会话：管理服务器列表、当前连接、登录状态。
@MainActor
public final class AppSession: ObservableObject {
    public enum AuthState: Equatable {
        case needsServer
        case loggedOut
        case authenticating
        case loggedIn
    }

    @Published public private(set) var servers: [ServerProfile] = []
    @Published public private(set) var activeServerID: UUID?
    @Published public private(set) var authState: AuthState = .needsServer
    @Published public private(set) var userInfo: JSONValue = .null
    @Published public private(set) var serverVersion: String?
    @Published public var lastErrorMessage: String?

    private var clients: [UUID: APIClient] = [:]

    public init() {
        servers = ServerStore.load()
        activeServerID = ServerStore.loadActiveID() ?? servers.first?.id
        authState = activeServer == nil ? .needsServer : .loggedOut
    }

    // MARK: - Servers

    public var activeServer: ServerProfile? {
        guard let activeServerID else { return nil }
        return servers.first { $0.id == activeServerID }
    }

    public var client: APIClient? {
        guard let profile = activeServer, let url = profile.baseURL else { return nil }
        if let existing = clients[profile.id], existing.baseURL == url { return existing }
        let created = APIClient(baseURL: url, serverID: profile.id,
                                allowInsecureTLS: profile.allowInsecureTLS)
        clients[profile.id] = created
        return created
    }

    public var api: CineChillAPI? {
        guard let client else { return nil }
        return CineChillAPI(client: client)
    }

    public func requireAPI() throws -> CineChillAPI {
        guard let api else { throw APIError.noServerConfigured }
        return api
    }

    public func upsert(_ profile: ServerProfile, password: String?) {
        if let index = servers.firstIndex(where: { $0.id == profile.id }) {
            servers[index] = profile
        } else {
            servers.append(profile)
        }
        clients[profile.id] = nil
        if let password, profile.rememberPassword, !password.isEmpty {
            Keychain.save(password, account: profile.passwordAccount)
        } else if profile.rememberPassword == false {
            Keychain.delete(account: profile.passwordAccount)
        }
        ServerStore.save(servers)
        if activeServerID == nil { select(profile.id) }
    }

    public func remove(_ profile: ServerProfile) {
        servers.removeAll { $0.id == profile.id }
        clients[profile.id] = nil
        Keychain.delete(account: profile.passwordAccount)
        ServerStore.save(servers)
        if activeServerID == profile.id {
            select(servers.first?.id)
        }
    }

    public func select(_ id: UUID?) {
        activeServerID = id
        ServerStore.saveActiveID(id)
        userInfo = .null
        serverVersion = nil
        authState = id == nil ? .needsServer : .loggedOut
    }

    public func savedPassword(for profile: ServerProfile) -> String? {
        Keychain.read(account: profile.passwordAccount)
    }

    // MARK: - Auth

    /// 用已保存的凭据尝试恢复会话：先探 `user_info`，失败再用 Keychain 里的密码登录。
    public func restoreSession() async {
        guard let profile = activeServer, let api else {
            authState = .needsServer
            return
        }
        authState = .authenticating
        if await probeUserInfo(api) {
            await loadVersion(api)
            authState = .loggedIn
            return
        }
        if let password = savedPassword(for: profile), !profile.username.isEmpty {
            do {
                try await login(username: profile.username, password: password)
                return
            } catch {
                lastErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
        authState = .loggedOut
    }

    public func login(username: String, password: String) async throws {
        guard var profile = activeServer, let api else { throw APIError.noServerConfigured }
        authState = .authenticating
        do {
            let response = try await api.auth.login(LoginRequest(username: username, password: password))
            if response.isSuccessFlag == false, let message = response.errorMessage {
                authState = .loggedOut
                throw APIError.server(status: 200, message: message)
            }
            if let token = APIClient.extractToken(from: response) {
                client?.updateToken(token)
            }
            profile.username = username
            profile.lastUsedAt = Date()
            upsert(profile, password: profile.rememberPassword ? password : nil)
            _ = await probeUserInfo(api)
            await loadVersion(api)
            authState = .loggedIn
            lastErrorMessage = nil
        } catch {
            authState = .loggedOut
            throw error
        }
    }

    public func logout() async {
        if let api {
            _ = try? await api.auth.logout()
        }
        client?.updateToken(nil)
        userInfo = .null
        authState = .loggedOut
    }

    public func changeCredentials(oldPassword: String, newUsername: String, newPassword: String) async throws {
        let api = try requireAPI()
        let response = try await api.auth.changeAuth(
            ChangeAuthRequest(oldPassword: oldPassword, newUsername: newUsername, newPassword: newPassword))
        if response.isSuccessFlag == false {
            throw APIError.server(status: 200, message: response.errorMessage ?? "修改失败")
        }
        if var profile = activeServer {
            profile.username = newUsername
            upsert(profile, password: profile.rememberPassword ? newPassword : nil)
        }
    }

    /// 供各页面在收到 401 时统一处理。
    public func handle(error: Error) {
        if let apiError = error as? APIError, apiError.isAuthFailure {
            authState = .loggedOut
        }
        if let localized = error as? LocalizedError, let text = localized.errorDescription {
            lastErrorMessage = text
        } else {
            lastErrorMessage = error.localizedDescription
        }
    }

    @discardableResult
    private func probeUserInfo(_ api: CineChillAPI) async -> Bool {
        do {
            let info = try await api.auth.getUserInfo()
            // 未登录时 FastAPI 侧通常回 401，也可能回 {"authenticated": false}
            if info["authenticated"].bool == false || info["logged_in"].bool == false {
                return false
            }
            if info.isNull { return false }
            userInfo = info
            return true
        } catch {
            return false
        }
    }

    private func loadVersion(_ api: CineChillAPI) async {
        if let version = try? await api.meta.apiVersion() {
            serverVersion = version["version"].displayString
                ?? version["api_version"].displayString
                ?? version.displayString
        }
    }

    public var displayUsername: String {
        userInfo.first(of: "username", "user", "name").displayString
            ?? activeServer?.username
            ?? "admin"
    }

    /// 把服务端返回的相对路径（如 `/api/cached_img?...`）拼成绝对地址。
    public func absoluteURL(_ raw: String?) -> URL? {
        guard let raw, !raw.isEmpty else { return nil }
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") { return URL(string: raw) }
        guard let base = activeServer?.baseURL else { return nil }
        let path = raw.hasPrefix("/") ? raw : "/" + raw
        return URL(string: path, relativeTo: base)?.absoluteURL
    }

    public func absoluteURL(_ value: JSONValue) -> URL? {
        absoluteURL(value.string)
    }
}

/// 可失败的辅助调用：仪表盘等页面会并发拉多个接口，个别失败不应让整页失败。
public enum Probe {
    public static func json(_ operation: () async throws -> JSONValue) async -> JSONValue {
        (try? await operation()) ?? .null
    }
}

