import Foundation

/// 与单台 CineChill 服务端通信的 HTTP 客户端。
///
/// - 会话凭据同时兼容两种方式：Cookie（`HTTPCookieStorage.shared` 自动携带）
///   与 Token（登录响应里出现 token 字段时，附加到 `Authorization: Bearer` 等请求头）。
/// - 所有 JSON 响应统一解码为 `JSONValue`，因为服务端 OpenAPI 未声明任何 200 响应结构。
public final class APIClient: @unchecked Sendable {
    public let baseURL: URL
    public let serverID: UUID
    private let session: URLSession
    private let lock = NSLock()
    private var token: String?

    public init(baseURL: URL, serverID: UUID = UUID(), token: String? = nil, allowInsecureTLS: Bool = false) {
        self.baseURL = baseURL
        self.serverID = serverID
        self.token = token
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.waitsForConnectivity = false
        if allowInsecureTLS {
            self.session = URLSession(configuration: config,
                                      delegate: InsecureTLSDelegate(host: baseURL.host),
                                      delegateQueue: nil)
        } else {
            self.session = URLSession(configuration: config)
        }
    }

    // MARK: - Token

    public var currentToken: String? {
        lock.lock(); defer { lock.unlock() }
        return token
    }

    public func updateToken(_ newValue: String?) {
        lock.lock(); token = newValue; lock.unlock()
    }

    /// 从登录响应里尽力提取会话令牌；没有令牌时返回 nil（此时依赖 Cookie）。
    public static func extractToken(from json: JSONValue) -> String? {
        let candidates = ["token", "access_token", "accessToken", "session_token",
                          "sessionToken", "session", "sid", "jwt", "api_key", "apiKey"]
        var queue: [JSONValue] = [json]
        var depth = 0
        while let current = queue.first, depth < 4 {
            queue.removeFirst()
            if let obj = current.object {
                for key in candidates {
                    if let s = obj[key]?.string, s.count >= 8 { return s }
                }
                queue.append(contentsOf: obj.values.filter { $0.object != nil })
            }
            if queue.isEmpty { depth += 1 }
        }
        return nil
    }

    // MARK: - URL building

    public func url(path: String, query: [String: String?]? = nil) throws -> URL {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard var comps = URLComponents(url: baseURL.appendingPathComponent(trimmed),
                                        resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL(path)
        }
        if let query {
            let items = query
                .compactMap { key, value -> URLQueryItem? in
                    guard let value else { return nil }
                    return URLQueryItem(name: key, value: value)
                }
                .sorted { $0.name < $1.name }
            if !items.isEmpty { comps.queryItems = items }
        }
        guard let built = comps.url else { throw APIError.invalidURL(path) }
        return built
    }

    // MARK: - Requests

    private func makeRequest(_ method: HTTPMethod, path: String,
                             query: [String: String?]?, timeout: TimeInterval) throws -> URLRequest {
        var request = URLRequest(url: try url(path: path, query: query))
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("CineChill-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        if let token = currentToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        }
        return request
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.withoutEscapingSlashes]
        return e
    }()

    private static let decoder = JSONDecoder()

    @discardableResult
    public func send(_ method: HTTPMethod, _ path: String,
                     query: [String: String?]? = nil,
                     timeout: TimeInterval = 30) async throws -> JSONValue {
        let request = try makeRequest(method, path: path, query: query, timeout: timeout)
        return try await perform(request)
    }

    @discardableResult
    public func send<B: Encodable>(_ method: HTTPMethod, _ path: String,
                                   query: [String: String?]? = nil,
                                   body: B,
                                   timeout: TimeInterval = 60) async throws -> JSONValue {
        var request = try makeRequest(method, path: path, query: query, timeout: timeout)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try Self.encoder.encode(body)
        } catch {
            throw APIError.decoding("请求体编码失败：\(error.localizedDescription)")
        }
        return try await perform(request)
    }

    /// 抓取原始字节（图片代理、导出文件等）。
    public func data(path: String, query: [String: String?]? = nil,
                     timeout: TimeInterval = 60) async throws -> Data {
        let request = try makeRequest(.get, path: path, query: query, timeout: timeout)
        let (data, response) = try await raw(request)
        try validate(response, data: data)
        return data
    }

    public func data(from url: URL, timeout: TimeInterval = 60) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        if let token = currentToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await raw(request)
        try validate(response, data: data)
        return data
    }

    /// multipart/form-data 上传（字体、Emby 用户头像）。
    @discardableResult
    public func upload(path: String, fieldName: String, fileData: Data, filename: String,
                       mimeType: String, query: [String: String?]? = nil) async throws -> JSONValue {
        var request = try makeRequest(.post, path: path, query: query, timeout: 300)
        let boundary = "CineChill-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        func append(_ text: String) { body.append(Data(text.utf8)) }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        append("\r\n--\(boundary)--\r\n")
        request.httpBody = body
        return try await perform(request)
    }

    /// SSE / 流式接口的请求对象，交给 `EventStream` 消费。
    public func streamRequest(method: HTTPMethod, path: String,
                              query: [String: String?]? = nil) throws -> URLRequest {
        var request = try makeRequest(method, path: path, query: query, timeout: 3600)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        return request
    }

    public func streamRequest<B: Encodable>(method: HTTPMethod, path: String,
                                            query: [String: String?]? = nil,
                                            body: B) throws -> URLRequest {
        var request = try streamRequest(method: method, path: path, query: query)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? Self.encoder.encode(body)
        return request
    }

    /// 供 `EventStream` 使用的字节流。
    public func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        do {
            return try await session.bytes(for: request)
        } catch let error as URLError {
            throw Self.map(error)
        }
    }

    // MARK: - Plumbing

    private func raw(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            throw Self.map(error)
        }
    }

    private static func map(_ error: URLError) -> APIError {
        switch error.code {
        case .cancelled: return .cancelled
        case .userAuthenticationRequired: return .unauthorized
        default: return .network(code: error.errorCode, message: error.localizedDescription)
        }
    }

    private func perform(_ request: URLRequest) async throws -> JSONValue {
        let (data, response) = try await raw(request)
        try validate(response, data: data)
        if data.isEmpty { return .null }
        do {
            return try Self.decoder.decode(JSONValue.self, from: data)
        } catch {
            // 非 JSON 响应（HTML 登录页、纯文本等）按字符串返回，交给上层判断。
            if let text = String(data: data, encoding: .utf8) { return .string(text) }
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard http.statusCode >= 400 else { return }
        let json = (try? Self.decoder.decode(JSONValue.self, from: data)) ?? .null
        switch http.statusCode {
        case 401, 403:
            throw APIError.unauthorized
        case 422:
            let messages = json["detail"].array?.compactMap { item -> String? in
                let field = item["loc"].array?.compactMap { $0.displayString }.joined(separator: ".")
                let msg = item["msg"].string ?? "无效值"
                if let field, !field.isEmpty { return "\(field) \(msg)" }
                return msg
            } ?? []
            throw APIError.validation(messages)
        default:
            let text = json.errorMessage ?? String(data: data.prefix(400), encoding: .utf8)
            throw APIError.server(status: http.statusCode, message: text)
        }
    }
}

/// 仅在用户为某台服务器显式勾选「允许自签名证书」时启用。
private final class InsecureTLSDelegate: NSObject, URLSessionDelegate {
    private let host: String?

    init(host: String?) {
        self.host = host
    }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              challenge.protectionSpace.host == host,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
