import SwiftUI

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

            let types = value["types"].list("types", "items", "data")
            Section("通知类型（\(types.count)）") {
                if types.isEmpty { EmptyRow("服务端未返回通知类型") }
                ForEach(Array(types.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.first(of: "label", "name", "title").displayString
                             ?? item.string ?? "—")
                            .font(.subheadline)
                        if let key = item.first(of: "key", "id", "type").displayString {
                            Text(key).font(.caption2).foregroundStyle(.tertiary)
                        }
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
            return try await api.notify.getNotificationDefaultTemplates()
        } content: { value, _ in
            Section("模板") {
                if value.sortedPairs.isEmpty { EmptyRow("没有默认模板") }
                JSONFieldList(value: value)
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
    @State private var testMessage = "CineChill 测试消息"
    @State private var confirmLogout = false

    var body: some View {
        RemoteList(title: "Telegram") {
            let api = try session.requireAPI()
            let config = await Probe.json { try await api.notify.getTelegramNotifyConfig() }
            let status = await Probe.json { try await api.notify.getTelegramStatus() }
            return JSONValue.object(["config": config, "status": status])
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
            .task { apply(value["config"]) }
        }
        .actionFeedback(runner)
    }

    private func apply(_ config: JSONValue) {
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
    }

    private func save(reload: Reload) {
        runner.run("已保存", operation: {
            let api = try session.requireAPI()
            return try await api.notify.saveTelegramNotifyConfig(
                TelegramNotifyConfigModel(enabled: enabled, name: name, botToken: botToken,
                                          chatId: chatID,
                                          accountMonitorEnabled: monitorEnabled,
                                          apiId: apiID, apiHash: apiHash, phone: phone,
                                          monitorReplyEnabled: monitorReply,
                                          monitorTransferMode: transferMode,
                                          transferDirMode: transferDirMode,
                                          transferDir: transferDir))
        }, onSuccess: {
            botToken = ""
            apiHash = ""
            await reload()
        })
    }
}
