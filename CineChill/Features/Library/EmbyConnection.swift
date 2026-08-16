import Foundation

/// Emby 连接参数。多个接口（总览、搜索、封面）都要求把 Emby 地址与 API Key 放在请求体里，
/// 这里从服务端配置接口里推断，避免用户在 App 内重复填写。
enum EmbyConnection {
    static func load(api: CineChillAPI) async -> ConnectionRequest? {
        // The web dashboard reads the 302 configuration, where Emby entries are
        // stored under `embys`. Keep `/api/load` as a fallback for older servers.
        let config302 = await Probe.json { try await api.config302.getConfig302() }
        if let connection = connection(from: config302) {
            return connection
        }
        let config = await Probe.json { try await api.server.loadConfig() }
        return connection(from: config)
    }

    /// 需要连接参数的动作用这个：读不到就抛错，交给 ActionRunner 弹提示。
    static func require(api: CineChillAPI) async throws -> ConnectionRequest {
        guard let connection = await load(api: api) else {
            throw APIError.validation(["未能读取 Emby 地址与 API Key，请先在「设置 → 服务器配置」中填写"])
        }
        return connection
    }

    static func connection(from config: JSONValue) -> ConnectionRequest? {
        var node = config.deepFirst(of: "embys", "emby", "emby_config", "media_server", "emby_servers")
        if let list = node.array { node = list.first ?? .null }
        let candidates = node.object != nil ? [node, config] : [config]
        for candidate in candidates {
            let url = candidate.deepFirst(of: "emby_url", "url", "server_url", "host", "address").string
            let key = candidate.deepFirst(of: "emby_key", "emby_api_key", "api_key", "key", "token").string
            if let url, let key, !url.isEmpty, !key.isEmpty {
                let publicHost = candidate.deepFirst(of: "public_host", "public_url", "external_url").string
                return ConnectionRequest(url: url, key: key, publicHost: publicHost)
            }
        }
        return nil
    }
}
