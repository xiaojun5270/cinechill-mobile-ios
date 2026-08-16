import SwiftUI

struct NotificationTypeDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
}

enum NotificationSettingsData {
    private static let metadataKeys: Set<String> = [
        "status", "message", "success", "ok", "detail", "error",
        "data", "result", "payload", "types", "templates"
    ]

    static func typeDefinitions(from response: JSONValue) -> [NotificationTypeDefinition] {
        let payload = unwrap(response, keys: ["types", "notification_types"])

        if let items = payload.array {
            return items.enumerated().compactMap { index, item in
                let key = item.first(of: "key", "id", "type").displayString
                    ?? item.string
                    ?? (item.object == nil ? nil : String(index))
                guard let key, !key.isEmpty else { return nil }
                return NotificationTypeDefinition(
                    id: key,
                    name: item.first(of: "name", "label", "title").displayString
                        ?? item.string
                        ?? key,
                    description: item.first(of: "description", "desc", "detail").displayString)
            }
        }

        guard let object = payload.object else { return [] }
        return object.keys
            .filter { !metadataKeys.contains($0) }
            .sorted()
            .map { key in
                let item = object[key] ?? .null
                return NotificationTypeDefinition(
                    id: key,
                    name: item.first(of: "name", "label", "title").displayString
                        ?? item.displayString
                        ?? key,
                    description: item.first(of: "description", "desc", "detail").displayString)
            }
    }

    static func notifyTypeValues(config: JSONValue,
                                 definitions: [NotificationTypeDefinition]) -> [String: Bool] {
        let raw = config.deepFirst(of: "notify_types", "notification_types")
        var values: [String: Bool] = [:]

        if let object = raw.object {
            for (key, value) in object {
                if let enabled = value.bool { values[key] = enabled }
            }
        } else if let items = raw.array {
            for item in items {
                if let key = item.first(of: "key", "id", "type").displayString ?? item.string {
                    values[key] = true
                }
            }
        }

        for definition in definitions where values[definition.id] == nil {
            values[definition.id] = raw.array == nil
        }
        return values
    }

    static func notifyTypeJSON(_ values: [String: Bool]) -> JSONValue {
        .object(values.mapValues { .bool($0) })
    }

    static func templateObject(from response: JSONValue) -> JSONValue {
        let payload = unwrap(response, keys: ["templates", "default_templates"])
        guard let object = payload.object else { return .object([:]) }
        return .object(object.filter { !metadataKeys.contains($0.key) })
    }

    static func configTemplates(from config: JSONValue) -> JSONValue {
        templateObject(from: config.deepFirst(of: "templates"))
    }

    static func mergedTemplates(defaults: JSONValue, custom: JSONValue) -> JSONValue {
        var merged = defaults.object ?? [:]
        for (key, customTemplate) in custom.object ?? [:] {
            if var fields = merged[key]?.object, let customFields = customTemplate.object {
                fields.merge(customFields) { _, new in new }
                merged[key] = .object(fields)
            } else {
                merged[key] = customTemplate
            }
        }
        return .object(merged)
    }

    static func templateKeys(_ templates: JSONValue, defaults: JSONValue) -> [String] {
        let preferred = ["media_added", "playback", "organize_complete", "wash_result", "task_complete"]
        let all = Set((templates.object ?? [:]).keys).union((defaults.object ?? [:]).keys)
        return preferred.filter(all.contains) + all.subtracting(preferred).sorted()
    }

    static func templateLabel(_ key: String,
                              definitions: [NotificationTypeDefinition]) -> String {
        if let definition = definitions.first(where: { $0.id == key }) {
            return "\(definition.name)模板"
        }
        let labels = [
            "media_added": "入库通知模板",
            "playback": "播放通知模板",
            "organize_complete": "整理通知模板",
            "wash_result": "洗版通知模板",
            "task_complete": "任务通知模板"
        ]
        return labels[key] ?? key
    }

    private static func unwrap(_ response: JSONValue, keys: [String]) -> JSONValue {
        var current = response
        for _ in 0..<4 {
            guard let object = current.object else { break }
            if let key = keys.first(where: { object[$0]?.isNull == false }),
               let nested = object[key] {
                current = nested
                continue
            }
            if let nested = ["data", "result", "payload"].compactMap({ object[$0] }).first,
               object.keys.allSatisfy({ metadataKeys.contains($0) }) {
                current = nested
                continue
            }
            break
        }
        return current
    }
}

struct NotificationOptionsEditor: View {
    let definitions: [NotificationTypeDefinition]
    @Binding var notifyTypes: [String: Bool]
    @Binding var templates: JSONValue
    let defaultTemplates: JSONValue
    @State private var expandedTemplates: Set<String> = []

    var body: some View {
        Group {
            Section("通知类型（\(definitions.count)）") {
                if definitions.isEmpty { EmptyRow("服务端未返回通知类型") }
                ForEach(definitions) { definition in
                    Toggle(isOn: typeBinding(definition.id)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(definition.name)
                            if let description = definition.description, !description.isEmpty {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(definition.id)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            let keys = NotificationSettingsData.templateKeys(templates, defaults: defaultTemplates)
            if !keys.isEmpty {
                Section("通知模板（\(keys.count)）") {
                    ForEach(keys, id: \.self) { key in
                        DisclosureGroup(isExpanded: expandedBinding(key)) {
                            TextField("标题模板", text: templateBinding(key, field: "title"), axis: .vertical)
                                .lineLimit(2...4)
                            TextField("正文模板", text: templateBinding(key, field: "text"), axis: .vertical)
                                .lineLimit(4...10)
                            Button {
                                resetTemplate(key)
                            } label: {
                                Label("恢复默认", systemImage: "arrow.counterclockwise")
                            }
                            .disabled(defaultTemplates[key].isNull)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NotificationSettingsData.templateLabel(key, definitions: definitions))
                                Text(key).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func typeBinding(_ key: String) -> Binding<Bool> {
        Binding(get: { notifyTypes[key] ?? true },
                set: { notifyTypes[key] = $0 })
    }

    private func templateBinding(_ key: String, field: String) -> Binding<String> {
        Binding(get: { templates[key][field].string ?? "" }, set: { value in
            var template = templates[key]
            template[field] = .string(value)
            templates[key] = template
        })
    }

    private func expandedBinding(_ key: String) -> Binding<Bool> {
        Binding(get: { expandedTemplates.contains(key) }, set: { expanded in
            if expanded { expandedTemplates.insert(key) } else { expandedTemplates.remove(key) }
        })
    }

    private func resetTemplate(_ key: String) {
        guard !defaultTemplates[key].isNull else { return }
        templates[key] = defaultTemplates[key]
    }
}

/// 通知渠道总览：Telegram、企业微信、通知类型与模板。
struct NotifyView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "通知渠道") {
            let api = try session.requireAPI()
            let channels = await Probe.json { try await api.notify.getNotificationChannels() }
            let types = await Probe.json { try await api.notify.getNotificationTypes() }
            let telegram = await Probe.json { try await api.notify.getTelegramStatus() }
            return JSONValue.object(["channels": channels, "types": types, "telegram": telegram])
        } content: { value, _ in
            Section("渠道") {
                ModuleRow(title: "Telegram",
                          subtitle: telegramSubtitle(value["telegram"]),
                          systemImage: "paperplane",
                          tint: .blue) { TelegramNotifyView() }
                ModuleRow(title: "企业微信",
                          subtitle: "应用消息推送",
                          systemImage: "message",
                          tint: .green) { WechatNotifyView() }
            }

            let channels = value["channels"].list("channels", "items", "data")
            if !channels.isEmpty {
                Section("服务端登记的渠道（\(channels.count)）") {
                    ForEach(Array(channels.enumerated()), id: \.offset) { _, channel in
                        HStack {
                            Text(channel.first(of: "name", "label", "id").displayString ?? "—")
                            Spacer()
                            if let enabled = channel.first(of: "enabled", "active").bool {
                                StatusBadge(enabled ? "启用" : "停用", tone: enabled ? .good : .neutral)
                            }
                        }
                    }
                }
            }

            let types = NotificationSettingsData.typeDefinitions(from: value["types"])
            Section("通知类型（\(types.count)）") {
                if types.isEmpty { EmptyRow("服务端未返回通知类型") }
                ForEach(types) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline)
                        if let description = item.description, !description.isEmpty {
                            Text(description).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(item.id).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }

            Section {
                NavigationLink {
                    NotifyTemplatesView()
                } label: {
                    Label("默认模板", systemImage: "text.quote")
                }
                JSONInspector(value: value)
            }
        }
    }

    private func telegramSubtitle(_ status: JSONValue) -> String {
        if status.deepFirst(of: "logged_in", "authorized", "connected").bool == true {
            return status.deepFirst(of: "username", "phone", "name").displayString ?? "已登录"
        }
        return "Bot 推送 / 账号监听"
    }
}

/// 默认通知模板（只读展示）。
struct NotifyTemplatesView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "默认模板") {
            let api = try session.requireAPI()
            let templates = try await api.notify.getNotificationDefaultTemplates()
            let types = await Probe.json { try await api.notify.getNotificationTypes() }
            return .object(["templates": templates, "types": types])
        } content: { value, _ in
            let templates = NotificationSettingsData.templateObject(from: value["templates"])
            let definitions = NotificationSettingsData.typeDefinitions(from: value["types"])
            let keys = NotificationSettingsData.templateKeys(templates, defaults: .object([:]))
            Section("模板（\(keys.count)）") {
                if keys.isEmpty { EmptyRow("没有默认模板") }
                ForEach(keys, id: \.self) { key in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(NotificationSettingsData.templateLabel(key, definitions: definitions))
                            .font(.subheadline)
                        if let title = templates[key]["title"].string, !title.isEmpty {
                            Text(title).font(.caption).foregroundStyle(.secondary)
                        }
                        if let text = templates[key]["text"].string, !text.isEmpty {
                            Text(text).font(.caption2).foregroundStyle(.tertiary).lineLimit(3)
                        }
                        Text(key).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
            Section { JSONInspector(value: value) }
        }
    }
}

/// Telegram 通知与账号监听。
struct TelegramNotifyView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var enabled = false
    @State private var name = "Telegram"
    @State private var botToken = ""
    @State private var chatID = ""
    @State private var monitorEnabled = false
    @State private var apiID = ""
    @State private var apiHash = ""
    @State private var phone = ""
    @State private var monitorReply = false
    @State private var transferMode = "all"
    @State private var transferDirMode = "system"
    @State private var transferDir = ""
    @State private var selectedDialogs: [JSONValue] = []
    @State private var notifyTypes: [String: Bool] = [:]
    @State private var templates: JSONValue = .object([:])
    @State private var defaultTemplates: JSONValue = .object([:])
    @State private var testMessage = "CineChill 测试消息"
    @State private var confirmLogout = false

    var body: some View {
        RemoteList(title: "Telegram") {
            let api = try session.requireAPI()
            let config = await Probe.json { try await api.notify.getTelegramNotifyConfig() }
            let status = await Probe.json { try await api.notify.getTelegramStatus() }
            let types = await Probe.json { try await api.notify.getNotificationTypes() }
            let defaults = await Probe.json { try await api.notify.getNotificationDefaultTemplates() }
            return JSONValue.object([
                "config": config, "status": status, "types": types, "defaults": defaults
            ])
        } content: { value, reload in
            Section("Bot 推送") {
                Toggle("启用", isOn: $enabled)
                TextField("渠道名称", text: $name)
                SecureField("Bot Token", text: $botToken)
                TextField("Chat ID", text: $chatID)
                    .textInputAutocapitalization(.never)
                TextField("测试内容", text: $testMessage)
                Button {
                    runner.run("已发送") {
                        let api = try session.requireAPI()
                        return try await api.notify.sendTelegramTestMessage(message: testMessage)
                    }
                } label: {
                    Label("发送测试消息", systemImage: "paperplane")
                }
                Button {
                    runner.run("测试完成") {
                        let api = try session.requireAPI()
                        return try await api.notify.testTelegramNotify()
                    }
                } label: {
                    Label("测试通知配置", systemImage: "bolt.horizontal")
                }
            }

            Section("账号监听") {
                Toggle("启用账号监听", isOn: $monitorEnabled)
                TextField("API ID", text: $apiID)
                    .textInputAutocapitalization(.never)
                SecureField("API Hash", text: $apiHash)
                TextField("手机号（+86…）", text: $phone)
                    .textInputAutocapitalization(.never)
                Toggle("回复消息", isOn: $monitorReply)
                Picker("转存范围", selection: $transferMode) {
                    Text("全部").tag("all")
                    Text("仅命中订阅").tag("subscribed")
                }
                Picker("目录来源", selection: $transferDirMode) {
                    Text("系统配置").tag("system")
                    Text("自定义").tag("custom")
                }
                if transferDirMode == "custom" {
                    TextField("自定义目录", text: $transferDir)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }

            Section("登录状态") {
                KeyValueRow("已登录", value["status"].deepFirst(of: "logged_in", "authorized"))
                KeyValueRow("账号", value["status"].deepFirst(of: "username", "phone", "name"))
                NavigationLink {
                    TelegramLoginView(apiID: apiID, apiHash: apiHash, phone: phone)
                } label: {
                    Label("登录 / 输入验证码", systemImage: "key")
                }
                NavigationLink {
                    TelegramDialogsView()
                } label: {
                    Label("选择监听会话", systemImage: "list.bullet.rectangle")
                }
                Button {
                    confirmLogout = true
                } label: {
                    Label("退出 Telegram 登录", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .foregroundStyle(.red)
            }

            NotificationOptionsEditor(
                definitions: NotificationSettingsData.typeDefinitions(from: value["types"]),
                notifyTypes: $notifyTypes,
                templates: $templates,
                defaultTemplates: defaultTemplates)

            Section {
                Button {
                    save(reload: reload)
                } label: {
                    Label("保存配置", systemImage: "square.and.arrow.down")
                }
                JSONInspector(value: value)
            } footer: {
                Text("Bot Token 与 API Hash 属于敏感凭据，留空表示保留服务器上已有的值。")
            }
            .confirmationDialog("退出 Telegram 登录？", isPresented: $confirmLogout, titleVisibility: .visible) {
                Button("退出", role: .destructive) {
                    runner.run("已退出", operation: {
                        let api = try session.requireAPI()
                        return try await api.notify.logoutTelegram()
                    }, onSuccess: { await reload() })
                }
                Button("取消", role: .cancel) {}
            }
            .task(id: value) { apply(value) }
        }
        .actionFeedback(runner)
    }

    private func apply(_ value: JSONValue) {
        let config = value["config"]
        let definitions = NotificationSettingsData.typeDefinitions(from: value["types"])
        let defaults = NotificationSettingsData.templateObject(from: value["defaults"])
        enabled = config.deepFirst(of: "enabled").bool ?? enabled
        name = config.deepFirst(of: "name").string ?? name
        chatID = config.deepFirst(of: "chat_id").displayString ?? chatID
        monitorEnabled = config.deepFirst(of: "account_monitor_enabled").bool ?? monitorEnabled
        apiID = config.deepFirst(of: "api_id").displayString ?? apiID
        phone = config.deepFirst(of: "phone").displayString ?? phone
        monitorReply = config.deepFirst(of: "monitor_reply_enabled").bool ?? monitorReply
        transferMode = config.deepFirst(of: "monitor_transfer_mode").string ?? transferMode
        transferDirMode = config.deepFirst(of: "transfer_dir_mode").string ?? transferDirMode
        transferDir = config.deepFirst(of: "transfer_dir").string ?? transferDir
        selectedDialogs = config.deepFirst(of: "selected_dialogs").array ?? selectedDialogs
        notifyTypes = NotificationSettingsData.notifyTypeValues(
            config: config, definitions: definitions)
        defaultTemplates = defaults
        templates = NotificationSettingsData.mergedTemplates(
            defaults: defaults,
            custom: NotificationSettingsData.configTemplates(from: config))
    }

    private func save(reload: Reload) {
        runner.run("已保存", operation: {
            let api = try session.requireAPI()
            return try await api.notify.saveTelegramNotifyConfig(
                TelegramNotifyConfigModel(enabled: enabled, name: name, botToken: botToken,
                                          chatId: chatID,
                                          accountMonitorEnabled: monitorEnabled,
                                          apiId: apiID, apiHash: apiHash, phone: phone,
                                          selectedDialogs: selectedDialogs,
                                          monitorReplyEnabled: monitorReply,
                                          monitorTransferMode: transferMode,
                                          transferDirMode: transferDirMode,
                                          transferDir: transferDir,
                                          notifyTypes: NotificationSettingsData.notifyTypeJSON(notifyTypes),
                                          templates: templates))
        }, onSuccess: {
            botToken = ""
            apiHash = ""
            await reload()
        })
    }
}
