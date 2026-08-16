import SwiftUI

/// AI 记忆与人设。
struct AIMemoryView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var robotPrompt = ""
    @State private var userPrompt = ""
    @State private var notesPrompt = ""

    var body: some View {
        RemoteList(title: "记忆与人设") {
            let api = try session.requireAPI()
            async let memoryRequest = api.ai.readAiAssistantMemory()
            async let profileRequest = Probe.json { try await api.ai.readAiAssistantMemoryProfile() }
            let memory = try await memoryRequest
            let profile = await profileRequest
            let effectiveProfile = profile.deepFirst(of: "robot_prompt", "user_prompt", "notes_prompt").isNull
                ? memory["global_profile"] : profile
            return .object([
                "profile": effectiveProfile,
                "memory": memory,
            ])
        } content: { value, reload in
            Section("助手人设") {
                TextField("助手设定", text: $robotPrompt, axis: .vertical)
                    .lineLimit(3...10)
            }
            Section("用户画像") {
                TextField("你的偏好", text: $userPrompt, axis: .vertical)
                    .lineLimit(3...10)
            }
            Section {
                TextField("长期备注", text: $notesPrompt, axis: .vertical)
                    .lineLimit(3...10)
                Button {
                    runner.run("已保存", operation: {
                        let api = try session.requireAPI()
                        return try await api.ai.updateAiAssistantMemoryProfile(
                            AIAssistantGlobalProfilePayload(robotPrompt: robotPrompt,
                                                            userPrompt: userPrompt,
                                                            notesPrompt: notesPrompt))
                    }, onSuccess: { await reload() })
                } label: {
                    Label("保存人设", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("备注")
            } footer: {
                Text("这三段文本会拼进每次对话的系统提示，用于让助手记住长期偏好。")
            }

            let users = value["memory"]["users"].object ?? [:]
            Section("用户长期记忆（\(users.count)）") {
                if users.isEmpty { EmptyRow("暂无用户长期记忆") }
                ForEach(users.keys.sorted(), id: \.self) { userID in
                    let entries = users[userID]?.list("memories", "items") ?? []
                    let preview = entries.compactMap {
                        $0.first(of: "memory", "text", "content").displayString
                    }.prefix(3).joined(separator: "；")
                    VStack(alignment: .leading, spacing: 3) {
                        Text(userID).font(.subheadline.weight(.medium))
                        Text("\(entries.count) 条记忆")
                            .font(.caption).foregroundStyle(.secondary)
                        if !preview.isEmpty {
                            Text(preview).font(.caption2).foregroundStyle(.tertiary).lineLimit(3)
                        }
                    }
                }
            }

            Section { JSONInspector(value: value) }
                .task { apply(value["profile"]) }
        }
        .actionFeedback(runner)
    }

    private func apply(_ profile: JSONValue) {
        robotPrompt = profile.deepFirst(of: "robot_prompt").string ?? robotPrompt
        userPrompt = profile.deepFirst(of: "user_prompt").string ?? userPrompt
        notesPrompt = profile.deepFirst(of: "notes_prompt").string ?? notesPrompt
    }
}

/// AI 提醒事项。
struct AIRemindersView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var status = ""
    @State private var queryKey = 0

    var body: some View {
        RemoteList(title: "提醒事项", cacheKey: "ai-reminders-\(queryKey)") {
            let api = try session.requireAPI()
            return try await api.ai.readAiAssistantReminders(
                status: status.isEmpty ? nil : status, limit: 100)
        } content: { value, reload in
            Section {
                Picker("状态", selection: $status) {
                    Text("全部").tag("")
                    Text("待执行").tag("scheduled")
                    Text("执行中").tag("running")
                    Text("已完成").tag("done")
                    Text("失败").tag("failed")
                    Text("已取消").tag("cancelled")
                    Text("已过期").tag("expired")
                }
                .onChange(of: status) { _, _ in queryKey += 1 }
            }

            Section {
                NavigationLink {
                    AIReminderEditorView(reminder: nil) {
                        reload.fire()
                    }
                } label: {
                    Label("新建提醒任务", systemImage: "plus.circle")
                }
            }

            let items = value.list("reminders", "items", "data", "records")
            Section("提醒（\(items.count)）") {
                if items.isEmpty { EmptyRow("没有提醒") }
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    reminderRow(item, reload: reload)
                }
            }

            Section { JSONInspector(value: value) }
        }
        .id(queryKey)
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func reminderRow(_ item: JSONValue, reload: Reload) -> some View {
        let id = item.first(of: "id", "reminder_id").displayString ?? ""
        let state = item.first(of: "status", "state").displayString ?? ""
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.first(of: "title", "content", "text").displayString ?? "AI 助手提醒")
                    .font(.subheadline)
                    .lineLimit(3)
                Spacer()
                if !state.isEmpty {
                    StatusBadge(Self.statusLabel(state), tone: badgeTone(for: state))
                }
            }
            Text(Self.taskSummary(item["task"]))
                .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            if let time = item.first(of: "run_at", "remind_at", "due_at", "time").displayString {
                Text(Fmt.relative(.string(time)))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            if let user = item["from_user"].displayString, !user.isEmpty {
                Text("接收用户：\(user)")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            if !id.isEmpty {
                HStack(spacing: 14) {
                    NavigationLink {
                        AIReminderEditorView(reminder: item) {
                            reload.fire()
                        }
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }

                    if state == "scheduled" {
                        Button("取消") {
                            runner.run("已取消", operation: {
                                let api = try session.requireAPI()
                                return try await api.ai.cancelAiAssistantReminder(reminderId: id)
                            }, onSuccess: { await reload() })
                        }
                    }
                    Button("删除") {
                        runner.run("已删除", operation: {
                            let api = try session.requireAPI()
                            return try await api.ai.deleteAiAssistantReminder(reminderId: id)
                        }, onSuccess: { await reload() })
                    }
                    .foregroundStyle(.red)
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
        }
    }

    private static func statusLabel(_ status: String) -> String {
        [
            "scheduled": "待执行",
            "running": "执行中",
            "done": "已完成",
            "failed": "失败",
            "cancelled": "已取消",
            "expired": "已过期",
        ][status] ?? status
    }

    private static func taskSummary(_ task: JSONValue) -> String {
        switch task["type"].string ?? "message" {
        case "weather":
            return "天气：\(task["location"].displayString ?? "未填写地区")"
        case "web_search":
            return "联网查询：\(task["query"].displayString ?? "未填写内容")"
        default:
            return task["message"].displayString ?? "普通提醒"
        }
    }
}

/// AI 提醒任务的新建与编辑表单。
struct AIReminderEditorView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var runner = ActionRunner()

    private let reminderID: String
    private let onSaved: () -> Void

    @State private var title: String
    @State private var fromUser: String
    @State private var runAt: Date
    @State private var taskType: String
    @State private var message: String
    @State private var location: String
    @State private var query: String

    init(reminder: JSONValue?, onSaved: @escaping () -> Void) {
        let item = reminder ?? .null
        let task = item["task"]
        let type = task["type"].string ?? "message"
        reminderID = item.first(of: "id", "reminder_id").displayString ?? ""
        self.onSaved = onSaved
        _title = State(initialValue: item["title"].string ?? "")
        _fromUser = State(initialValue: item["from_user"].string ?? "")
        _runAt = State(initialValue: Self.date(from: item["run_at"]) ?? Date().addingTimeInterval(3_600))
        _taskType = State(initialValue: ["message", "weather", "web_search"].contains(type) ? type : "message")
        _message = State(initialValue: task["message"].string ?? item["title"].string ?? "")
        _location = State(initialValue: task["location"].string ?? "")
        _query = State(initialValue: task["query"].string ?? "")
    }

    var body: some View {
        Form {
            Section("任务信息") {
                TextField("提醒标题", text: $title)
                TextField("接收用户 ID（可选）", text: $fromUser)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                DatePicker("执行时间", selection: $runAt)
                Picker("任务类型", selection: $taskType) {
                    Text("普通提醒").tag("message")
                    Text("天气提醒").tag("weather")
                    Text("联网查询").tag("web_search")
                }
                .pickerStyle(.menu)
            }

            Section("任务参数") {
                switch taskType {
                case "weather":
                    TextField("天气地区", text: $location)
                case "web_search":
                    TextField("查询内容", text: $query, axis: .vertical)
                        .lineLimit(2...5)
                default:
                    TextField("提醒内容", text: $message, axis: .vertical)
                        .lineLimit(3...8)
                }
            }

            Section {
                Button {
                    save()
                } label: {
                    Label(reminderID.isEmpty ? "创建提醒" : "保存提醒",
                          systemImage: "square.and.arrow.down")
                }
                .disabled(!isValid)
            }
        }
        .navigationTitle(reminderID.isEmpty ? "新建提醒" : "编辑提醒")
        .actionFeedback(runner)
    }

    private var isValid: Bool {
        switch taskType {
        case "weather": return !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case "web_search": return !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func save() {
        runner.run(reminderID.isEmpty ? "提醒任务已创建" : "提醒任务已保存", operation: {
            let api = try session.requireAPI()
            if reminderID.isEmpty {
                return try await api.ai.createAiAssistantReminder(payload)
            }
            return try await api.ai.updateAiAssistantReminder(reminderId: reminderID, payload)
        }, onSuccess: {
            onSaved()
            dismiss()
        })
    }

    private var payload: JSONValue {
        let task: JSONValue
        switch taskType {
        case "weather":
            task = .object(["type": .string("weather"), "location": .string(location)])
        case "web_search":
            task = .object(["type": .string("web_search"),
                            "query": .string(query), "limit": .int(5)])
        default:
            task = .object(["type": .string("message"),
                            "message": .string(message.isEmpty ? title : message)])
        }
        let timestamp = Self.formatter.string(from: runAt)
        return .object([
            "title": .string(title),
            "from_user": .string(fromUser),
            "run_at": .string(timestamp),
            "run_at_text": .string(timestamp),
            "task": task,
        ])
    }

    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func date(from value: JSONValue) -> Date? {
        if let seconds = value.double { return Date(timeIntervalSince1970: seconds) }
        guard let text = value.string else { return nil }
        if let parsed = formatter.date(from: text) { return parsed }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: text)
    }
}

/// AI 工具权限与按服务端 schema 生成的工具配置入口。
struct AIToolPermissionsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "工具权限") {
            let api = try session.requireAPI()
            return try await api.ai.readAiAssistantToolPermissions()
        } content: { value, reload in
            let tools = value["tools"].object ?? [:]
            let enabledCount = tools.values.filter { $0["enabled"].bool == true }.count

            Section("概览") {
                KeyValueRow("工具总数", String(tools.count))
                KeyValueRow("已启用", String(enabledCount))
            }

            Section("工具列表") {
                if tools.isEmpty { EmptyRow("服务端没有返回工具权限") }
                ForEach(tools.keys.sorted(), id: \.self) { toolID in
                    let tool = tools[toolID] ?? .null
                    NavigationLink {
                        AIToolEditorView(toolID: toolID, tool: tool) {
                            reload.fire()
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(tool["label"].displayString ?? toolID)
                                Spacer()
                                StatusBadge(tool["enabled"].bool == true ? "已启用" : "已停用",
                                            tone: tool["enabled"].bool == true ? .good : .neutral)
                            }
                            Text(toolID)
                                .font(.caption2).foregroundStyle(.tertiary)
                            if tool["configurable"].bool == true {
                                Text("包含可配置参数")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AIToolEditorView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var runner = ActionRunner()

    private let toolID: String
    private let tool: JSONValue
    private let onSaved: () -> Void

    @State private var enabled: Bool
    @State private var config: JSONValue

    init(toolID: String, tool: JSONValue, onSaved: @escaping () -> Void) {
        self.toolID = toolID
        self.tool = tool
        self.onSaved = onSaved
        _enabled = State(initialValue: tool["enabled"].bool ?? false)
        _config = State(initialValue: tool["config"].object == nil ? .object([:]) : tool["config"])
    }

    var body: some View {
        Form {
            Section("权限") {
                Toggle("启用工具", isOn: $enabled)
                KeyValueRow("工具 ID", toolID, monospaced: true)
            }

            if schemaFields.isEmpty == false {
                Section("工具参数") {
                    ForEach(Array(schemaFields.enumerated()), id: \.offset) { _, field in
                        fieldEditor(field)
                    }
                }
            }

            Section {
                Button {
                    save()
                } label: {
                    Label("保存工具配置", systemImage: "square.and.arrow.down")
                }
            }
        }
        .navigationTitle(tool["label"].displayString ?? toolID)
        .actionFeedback(runner)
    }

    private var schemaFields: [JSONValue] {
        tool.path("config_schema", "fields").array ?? []
    }

    @ViewBuilder
    private func fieldEditor(_ field: JSONValue) -> some View {
        let key = field["key"].displayString ?? ""
        let label = field["label"].displayString ?? key
        let binding = $config.child(key)
        switch field["type"].string ?? "text" {
        case "secret":
            SecureField(label, text: binding.asString)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        case "select":
            Picker(label, selection: binding.asString) {
                ForEach(Array((field["options"].array ?? []).enumerated()), id: \.offset) { _, option in
                    let value = option["value"].displayString ?? ""
                    Text(option["label"].displayString ?? value).tag(value)
                }
            }
            .pickerStyle(.menu)
        case "toggle":
            Toggle(label, isOn: binding.asBool)
        default:
            TextField(field["placeholder"].displayString ?? label, text: binding.asString)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    private func save() {
        var update: [String: JSONValue] = ["enabled": .bool(enabled)]
        if tool["configurable"].bool == true {
            update["config"] = config
        }
        let updateValue = JSONValue.object(update)
        runner.run("工具配置已保存", operation: {
            let api = try session.requireAPI()
            return try await api.ai.updateAiAssistantToolPermissions(.object([
                "tools": .object([
                    toolID: updateValue,
                ]),
            ]))
        }, onSuccess: {
            onSaved()
            dismiss()
        })
    }
}

/// AI 调用审计。
struct AIAuditView: View {
    @EnvironmentObject private var session: AppSession
    @State private var limit = 100
    @State private var queryKey = 0

    var body: some View {
        RemoteList(title: "调用审计", cacheKey: "ai-audit-\(queryKey)") {
            let api = try session.requireAPI()
            return try await api.ai.readAiAssistantAudit(limit: limit)
        } content: { value, _ in
            Section {
                Stepper("最近 \(limit) 条", value: $limit, in: 20...500, step: 20)
                    .onChange(of: limit) { _, _ in queryKey += 1 }
            }
            let items = value.list("events", "audit", "items", "records", "data", "logs")
            Section("记录（\(items.count)）") {
                if items.isEmpty { EmptyRow("没有审计记录") }
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(item.first(of: "event", "tool", "action", "name").displayString ?? "事件")
                                .font(.caption.weight(.medium))
                            Spacer()
                            if let state = item.first(of: "status", "result").displayString {
                                StatusBadge(state, tone: badgeTone(for: state))
                            }
                        }
                        if let detail = item.first(of: "tool", "reason", "reply_preview",
                                                   "result_reason", "detail", "summary", "message").displayString {
                            Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(3)
                        }
                        if let time = item.first(of: "created_at", "timestamp", "time").displayString {
                            Text(Fmt.relative(.string(time)))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            Section { JSONInspector(value: value) }
        }
        .id(queryKey)
    }
}

/// AI 当前上下文（只读）。
struct AIContextView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "当前上下文") {
            let api = try session.requireAPI()
            return try await api.ai.readAiAssistantContext()
        } content: { value, _ in
            let users = value["users"].object ?? [:]
            let conversationCount = users.values.filter {
                $0["conversation_context"].object != nil
            }.count
            Section("概览") {
                KeyValueRow("用户数", String(users.count))
                KeyValueRow("上下文会话", "\(conversationCount) 个")
            }

            Section("用户上下文") {
                if users.isEmpty { EmptyRow("暂无上下文") }
                ForEach(users.keys.sorted(), id: \.self) { userID in
                    let context = users[userID]?["conversation_context"] ?? .null
                    let interactions = context.list("recent_interactions", "messages", "items")
                    VStack(alignment: .leading, spacing: 3) {
                        Text(userID).font(.subheadline.weight(.medium))
                        Text("\(interactions.count) 轮近期上下文")
                            .font(.caption).foregroundStyle(.secondary)
                        if let summary = context["summary"].displayString, !summary.isEmpty {
                            Text(summary)
                                .font(.caption2).foregroundStyle(.tertiary).lineLimit(5)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            Section { JSONInspector(value: value) }
        }
    }
}
