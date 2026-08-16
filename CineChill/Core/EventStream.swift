import Foundation

/// 一条 SSE 事件。
public struct SSEEvent: Sendable, Hashable {
    public var id: String?
    public var event: String?
    public var data: String

    public var json: JSONValue {
        guard let raw = data.data(using: .utf8), !raw.isEmpty else { return .null }
        return (try? JSONDecoder().decode(JSONValue.self, from: raw)) ?? .string(data)
    }
}

/// 把 `text/event-stream` 拆成事件序列。服务端的 `/api/discover/events`、
/// `/api/system_logs/stream`、`/api/forward/search_resources/stream` 都走这里。
public enum EventStream {
    public static func events(client: APIClient, request: URLRequest) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await client.bytes(for: request)
                    if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                        if http.statusCode == 401 || http.statusCode == 403 {
                            throw APIError.unauthorized
                        }
                        throw APIError.server(status: http.statusCode, message: nil)
                    }
                    var id: String?
                    var event: String?
                    var dataLines: [String] = []

                    func flush() {
                        guard !dataLines.isEmpty || event != nil else { return }
                        continuation.yield(SSEEvent(id: id, event: event,
                                                    data: dataLines.joined(separator: "\n")))
                        id = nil
                        event = nil
                        dataLines.removeAll()
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        if line.isEmpty {
                            flush()
                        } else if line.hasPrefix(":") {
                            continue // 心跳注释
                        } else if let separator = line.firstIndex(of: ":") {
                            let field = String(line[line.startIndex..<separator])
                            var value = String(line[line.index(after: separator)...])
                            if value.hasPrefix(" ") { value.removeFirst() }
                            switch field {
                            case "id": id = value
                            case "event": event = value
                            case "data": dataLines.append(value)
                            default: break
                            }
                        }
                    }
                    flush()
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
