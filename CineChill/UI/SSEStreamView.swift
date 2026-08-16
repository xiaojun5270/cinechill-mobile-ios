import SwiftUI

/// 通用 SSE 观察器：把服务端推来的事件按时间倒序列出来，点开看完整 JSON。
/// 用于 `/api/discover/events` 与 `/api/forward/search_resources/stream` 这类长连接接口。
struct SSEStreamView: View {
    let title: String
    var note: String?
    let makeRequest: (CineChillAPI) throws -> URLRequest

    @EnvironmentObject private var session: AppSession
    @State private var events: [Item] = []
    @State private var isConnected = false
    @State private var isFinished = false
    @State private var errorText: String?
    @State private var attempt = 0

    /// 一条已收到的事件。
    struct Item: Identifiable {
        let id = UUID()
        var name: String
        var summary: String
        var payload: JSONValue
    }

    init(title: String, note: String? = nil, makeRequest: @escaping (CineChillAPI) throws -> URLRequest) {
        self.title = title
        self.note = note
        self.makeRequest = makeRequest
    }

    var body: some View {
        List {
            Section("连接") {
                HStack {
                    StatusBadge(statusText, tone: isConnected ? .good : (isFinished ? .info : .neutral))
                    Spacer()
                    Text("\(events.count) 条事件").font(.caption).foregroundStyle(.secondary)
                }
                if let errorText {
                    FailureRow(message: errorText) { attempt += 1 }
                } else {
                    Button {
                        attempt += 1
                    } label: {
                        Label("重新连接", systemImage: "arrow.clockwise")
                    }
                    .disabled(isConnected)
                }
            }

            Section("事件") {
                if events.isEmpty { EmptyRow(isConnected ? "等待事件…" : "暂无事件") }
                ForEach(events.reversed()) { item in
                    NavigationLink {
                        JSONRawScreen(value: item.payload, title: item.name)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name).font(.subheadline.weight(.medium))
                            if !item.summary.isEmpty {
                                Text(item.summary)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }

            if let note {
                Section { Text(note).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle(title)
        .task(id: attempt) { await listen() }
    }

    private var statusText: String {
        if isConnected { return "已连接" }
        return isFinished ? "已结束" : "已断开"
    }

    private func listen() async {
        errorText = nil
        isFinished = false
        do {
            let api = try session.requireAPI()
            let request = try makeRequest(api)
            isConnected = true
            for try await event in EventStream.events(client: api.client, request: request) {
                if let name = event.event, name == "ping" || name == "heartbeat" { continue }
                append(event)
            }
            isConnected = false
            isFinished = true
        } catch let error as APIError {
            isConnected = false
            if error.isAuthFailure { session.handle(error: error) }
            if case .cancelled = error {} else { errorText = error.errorDescription }
        } catch {
            isConnected = false
            errorText = error.localizedDescription
        }
    }

    private func append(_ event: SSEEvent) {
        let payload = event.json
        let name = event.event
            ?? payload.first(of: "event", "type", "action").displayString
            ?? "message"
        events.append(Item(name: name, summary: Self.summary(of: payload), payload: payload))
        if events.count > 500 { events.removeFirst(events.count - 500) }
    }

    /// 事件结构未知，挑最像「一句话说明」的字段，实在没有就用压缩后的原文。
    static func summary(of payload: JSONValue) -> String {
        if let text = payload.first(of: "message", "title", "name", "status", "detail").displayString {
            return text
        }
        if let text = payload.string { return text }
        let pairs = payload.sortedPairs.prefix(3).map { "\($0.key)=\($0.value.displayString ?? "…")" }
        return pairs.joined(separator: "  ")
    }
}
