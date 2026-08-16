import Foundation
import Security

/// 服务器密码只落 Keychain，不进 UserDefaults。
public enum Keychain {
    private static let service = "com.cinechill.ios.credentials"

    public static func save(_ value: String, account: String) {
        let data = Data(value.utf8)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(query as CFDictionary, nil)
    }

    public static func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// 一台 CineChill 服务端的连接配置。密码不在这里，存 Keychain。
public struct ServerProfile: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var scheme: String
    public var host: String
    public var port: Int
    public var username: String
    public var allowInsecureTLS: Bool
    public var rememberPassword: Bool
    public var lastUsedAt: Date?

    public init(id: UUID = UUID(), name: String = "", scheme: String = "http", host: String = "",
                port: Int = 5256, username: String = "", allowInsecureTLS: Bool = false,
                rememberPassword: Bool = true, lastUsedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.scheme = scheme
        self.host = host
        self.port = port
        self.username = username
        self.allowInsecureTLS = allowInsecureTLS
        self.rememberPassword = rememberPassword
        self.lastUsedAt = lastUsedAt
    }

    public var displayName: String {
        name.isEmpty ? "\(host):\(port)" : name
    }

    public var baseURLString: String {
        "\(scheme)://\(host):\(port)"
    }

    public var baseURL: URL? {
        var comps = URLComponents()
        comps.scheme = scheme
        comps.host = host
        comps.port = port
        return comps.url
    }

    public var passwordAccount: String { "server-\(id.uuidString)" }

    public var isValid: Bool {
        !host.trimmingCharacters(in: .whitespaces).isEmpty && port > 0 && port <= 65535
    }

    /// 解析用户粘贴的地址，支持 `192.168.1.10:5256`、`http://host:5256`、`https://host/`。
    public static func parse(address raw: String) -> (scheme: String, host: String, port: Int)? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        var scheme = "http"
        if let range = text.range(of: "://") {
            scheme = String(text[text.startIndex..<range.lowerBound]).lowercased()
            text = String(text[range.upperBound...])
        }
        if let slash = text.firstIndex(of: "/") {
            text = String(text[text.startIndex..<slash])
        }
        guard !text.isEmpty else { return nil }
        var host = text
        var port = scheme == "https" ? 443 : 5256
        if let colon = text.lastIndex(of: ":"), !text.hasPrefix("[") {
            host = String(text[text.startIndex..<colon])
            if let parsed = Int(text[text.index(after: colon)...]), parsed > 0, parsed <= 65535 {
                port = parsed
            }
        }
        guard !host.isEmpty else { return nil }
        return (scheme, host, port)
    }
}

/// 服务器列表持久化（UserDefaults 存配置，Keychain 存密码）。
public enum ServerStore {
    private static let profilesKey = "cinechill.servers"
    private static let activeKey = "cinechill.activeServer"

    public static func load() -> [ServerProfile] {
        guard let data = UserDefaults.standard.data(forKey: profilesKey),
              let list = try? JSONDecoder().decode([ServerProfile].self, from: data) else { return [] }
        return list
    }

    public static func save(_ profiles: [ServerProfile]) {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: profilesKey)
    }

    public static func loadActiveID() -> UUID? {
        guard let raw = UserDefaults.standard.string(forKey: activeKey) else { return nil }
        return UUID(uuidString: raw)
    }

    public static func saveActiveID(_ id: UUID?) {
        if let id {
            UserDefaults.standard.set(id.uuidString, forKey: activeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeKey)
        }
    }
}
