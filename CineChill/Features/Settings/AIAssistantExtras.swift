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
            let profile = await Probe.json { try await api.ai.readAiAssistantMemoryProfile() }
            let memory = await Probe.json { try await api.ai.readAiAssistantMemory() }
            return JSONValue.object(["profile": profile, "memory": memory])
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

            let memories = value["memory"].list("memories", "items", "records", "data")
            Section("记忆条目（\(memories.count)）") {
                if memories.isEmpty { EmptyRow("没有记忆条目") }
                ForEach(Array(memories.prefix(100).enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.first(of: "content", "text", "summary").displayString ?? "—")
                            .font(.caption)
                            .lineLimit(4)
                        if let time = item.first(of: "created_at", "time", "updated_at").displayString {
                            Text(Fmt.relative(.string(time)))
                                .font(.caption2).foregroundStyle(.tertiary)
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
    @State private var draftText = ""
    @State private var draftDate = Date().addingTimeInterval(3600)
    @State private var queryKey = 0

    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    var body: some View {
        RemoteList(title: "提醒事项") {
            let api = try session.requireAPI()
            return try await api.ai.readAiAssistantReminders(
                status: status.isEmpty ? nil : status, limit: 100)
        } content: { value, reload in
            Section {
                Picker("状态", selection: $status) {
                    Text("全部").tag("")
                    Text("待处理").tag("pending")
                    Text("已完成").tag("done")
                    Text("已取消").tag("cancelled")
                }
                .onChange(of: status) { _, _ in queryKey += 1 }
            }

            Section("新建提醒") {
                TextField("提醒内容", text: $draftText, axis: .vertical)
                DatePicker("提醒时间", selection: $draftDate)
                Button {
                    runner.run("已创建", operation: {
                        let api = try session.requireAPI()
                        let iso = Self.formatter.string(from: draftDate)
                        return try await api.ai.createAiAssistantReminder(
                            .object(["content": .string(draftText),
                                     "text": .string(draftText),
                                     "remind_at": .string(iso),
                                     "status": .string("pending")]))
                    }, onSuccess: {
                        draftText = ""
                        await reload()
                    })
                } label: {
                    Label("创建", systemImage: "plus.circle")
                }
                .disabled(draftText.isEmpty)
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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.first(of: "content", "text", "title").displayString ?? "—")
                    .font(.subheadline)
                    .lineLimit(3)
                Spacer()
                if let state = item.first(of: "status", "state").displayString {
                    StatusBadge(state, tone: badgeTone(for: state))
                }
            }
            if let time = item.first(of: "remind_at", "due_at", "time").displayString {
                Text(Fmt.relative(.string(time)))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            if !id.isEmpty {
                HStack(spacing: 14) {
                    Button("取消") {
                        runner.run("已取消", operation: {
                            let api = try session.requireAPI()
                            return try await api.ai.cancelAiAssistantReminder(reminderId: id)
                        }, onSuccess: { await reload() })
                    }
                    Button("完成") {
                        runner.run("已更新", operation: {
                            let api = try session.requireAPI()
                            return try await api.ai.updateAiAssistantReminder(
                                reminderId: id, .object(["status": .string("done")]))
                        }, onSuccess: { await reload() })
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
}

/// AI 工具权限（原始编辑，服务端结构未声明）。
struct AIToolPermissionsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        JSONConfigScreen(
            title: "工具权限",
            note: "控制助手可以调用哪些服务端工具。true 表示允许，false 表示禁止。",
            unwrapKeys: ["permissions", "data", "config"],
            load: {
                let api = try session.requireAPI()
                return try await api.ai.readAiAssistantToolPermissions()
            },
            save: { edited in
                let api = try session.requireAPI()
                return try await api.ai.updateAiAssistantToolPermissions(edited)
            })
    }
}

/// AI 调用审计。
struct AIAuditView: View {
    @EnvironmentObject private var session: AppSession
    @State private var limit = 100
    @State private var queryKey = 0

    var body: some View {
        RemoteList(title: "调用审计") {
            let api = try session.requireAPI()
            return try await api.ai.readAiAssistantAudit(limit: limit)
        } content: { value, _ in
            Section {
                Stepper("最近 \(limit) 条", value: $limit, in: 20...500, step: 20)
                    .onChange(of: limit) { _, _ in queryKey += 1 }
            }
            let items = value.list("audit", "items", "records", "data", "logs")
            Section("记录（\(items.count)）") {
                if items.isEmpty { EmptyRow("没有审计记录") }
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(item.first(of: "tool", "action", "name").displayString ?? "—")
                                .font(.caption.weight(.medium))
                            Spacer()
                            if let state = item.first(of: "status", "result").displayString {
                                StatusBadge(state, tone: badgeTone(for: state))
                            }
                        }
                        if let detail = item.first(of: "detail", "summary", "message", "args").displayString {
                            Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(3)
                        }
                        if let time = item.first(of: "created_at", "time").displayString {
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
            Section("概览") {
                KeyValueRow("消息数", value.deepFirst(of: "message_count", "count"))
                KeyValueRow("Token 估算", value.deepFirst(of: "tokens", "token_count"))
                KeyValueRow("已压缩", value.deepFirst(of: "compressed", "was_compressed"))
            }
            let messages = value.list("messages", "context", "items")
            Section("消息（\(messages.count)）") {
                if messages.isEmpty { EmptyRow("上下文为空") }
                ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(message.first(of: "role", "from").displayString ?? "—")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(message.first(of: "content", "text").displayString ?? "—")
                            .font(.caption)
                            .lineLimit(8)
                            .textSelection(.enabled)
                    }
                }
            }
            Section { JSONInspector(value: value) }
        }
    }
}
