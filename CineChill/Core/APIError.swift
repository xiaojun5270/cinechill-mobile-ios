import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public enum APIError: LocalizedError, Sendable {
    case noServerConfigured
    case invalidURL(String)
    case network(code: Int, message: String)
    case unauthorized
    case validation([String])
    case server(status: Int, message: String?)
    case decoding(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .noServerConfigured:
            return "尚未配置服务器，请先在「设置 → 服务器」中添加。"
        case .invalidURL(let s):
            return "地址无法解析：\(s)"
        case .network(_, let message):
            return "网络请求失败：\(message)"
        case .unauthorized:
            return "登录已失效，请重新登录。"
        case .validation(let messages):
            return messages.isEmpty ? "参数校验失败（422）。" : "参数校验失败：" + messages.joined(separator: "；")
        case .server(let status, let message):
            if let message, !message.isEmpty { return "服务端返回 \(status)：\(message)" }
            return "服务端返回 \(status)。"
        case .decoding(let s):
            return "响应解析失败：\(s)"
        case .cancelled:
            return "请求已取消。"
        }
    }

    public var isAuthFailure: Bool {
        if case .unauthorized = self { return true }
        return false
    }

    /// POST 已经发出后连接中断或超时，服务端可能仍在执行，调用方不应盲目重试。
    public var isAmbiguousWriteCompletion: Bool {
        guard case .network(let code, _) = self else { return false }
        return code == URLError.Code.networkConnectionLost.rawValue
            || code == URLError.Code.timedOut.rawValue
    }
}

/// 查询参数序列化，生成代码统一走这里。
public enum Query {
    public static func value(_ v: String?) -> String? { v }
    public static func value(_ v: Int?) -> String? { v.map(String.init) }
    public static func value(_ v: Bool?) -> String? { v.map { $0 ? "true" : "false" } }
    public static func value(_ v: Double?) -> String? {
        guard let v, v.isFinite else { return nil }
        if v == v.rounded(), abs(v) < 1e15 { return String(Int(v)) }
        return String(v)
    }
    public static func value(_ v: JSONValue?) -> String? {
        guard let v, !v.isNull else { return nil }
        if let s = v.displayString { return s }
        if let arr = v.array { return arr.compactMap { $0.displayString }.joined(separator: ",") }
        return nil
    }
}

/// 路径参数转义，生成代码统一走这里。
public enum Path {
    private static let allowed: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~")
        return set
    }()

    public static func escape(_ raw: String) -> String {
        raw.addingPercentEncoding(withAllowedCharacters: allowed) ?? raw
    }
}
