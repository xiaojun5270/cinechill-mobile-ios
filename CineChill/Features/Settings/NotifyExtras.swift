import SwiftUI

/// Telegram 账号登录：发送验证码 + 登录。
struct TelegramLoginView: View {
    // 给默认值，这样既能被 NotifyView 带着凭据推进来，也能从「全部功能」里空手打开
    @State var apiID = ""
    @State var apiHash = ""
    @State var phone = ""

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var code = ""
    @State private var password = ""

    var body: some View {
        Form {
            Section("应用凭据") {
                TextField("API ID", text: $apiID)
                    .textInputAutocapitalization(.never)
                SecureField("API Hash", text: $apiHash)
                TextField("手机号（+86…）", text: $phone)
                    .textInputAutocapitalization(.never)
                Button {
                    runner.run("验证码已发送") {
                        let api = try session.requireAPI()
                        return try await api.notify.sendTelegramLoginCode(
                            TelegramSendCodeRequest(apiId: apiID, apiHash: apiHash, phone: phone))
                    }
                } label: {
                    Label("发送登录验证码", systemImage: "paperplane")
                }
                .disabled(apiID.isEmpty || apiHash.isEmpty || phone.isEmpty)
            }

            Section {
                TextField("验证码", text: $code)
                    .textInputAutocapitalization(.never)
                SecureField("二次验证密码（如有）", text: $password)
                Button {
                    runner.run("登录成功") {
                        let api = try session.requireAPI()
                        return try await api.notify.signInTelegram(
                            TelegramSignInRequest(code: code, password: password))
                    }
                } label: {
                    Label("完成登录", systemImage: "checkmark.circle")
                }
                .disabled(code.isEmpty)
            } header: {
                Text("验证码")
            } footer: {
                Text("验证码由 Telegram 官方客户端下发。开启两步验证的账号需要同时填写二次验证密码。")
            }

            if runner.lastResult.isNull == false {
                Section("返回") { JSONFieldList(value: runner.lastResult) }
            }
        }
        .navigationTitle("Telegram 登录")
        .actionFeedback(runner)
    }
}

/// 选择要监听的 Telegram 会话。
struct TelegramDialogsView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var selected: Set<String> = []

    var body: some View {
        RemoteList(title: "监听会话") {
            let api = try session.requireAPI()
            async let dialogsRequest = api.notify.listTelegramDialogs()
            async let configRequest = Probe.json { try await api.notify.getTelegramNotifyConfig() }
            let dialogs = try await dialogsRequest
            let config = await configRequest
            return .object(["dialogs": dialogs, "config": config])
        } content: { value, reload in
            let loadedDialogs = value["dialogs"].list("dialogs", "items", "data", "chats")
            let savedDialogs = value["config"].deepFirst(of: "selected_dialogs").array ?? []
            let dialogs = Self.mergedDialogs(loaded: loadedDialogs, saved: savedDialogs)
            Section("会话（\(dialogs.count)）") {
                if dialogs.isEmpty { EmptyRow("没有可选会话，请先完成 Telegram 登录") }
                ForEach(Array(dialogs.enumerated()), id: \.offset) { _, dialog in
                    let id = Self.identifier(dialog)
                    Button {
                        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
                    } label: {
                        HStack {
                            avatar(dialog)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dialog.first(of: "title", "name", "username").displayString ?? id)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(id).font(.caption2).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            if selected.contains(id) {
                                Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    let picked = dialogs.filter { selected.contains(Self.identifier($0)) }
                    runner.run("已保存", operation: {
                        let api = try session.requireAPI()
                        return try await api.notify.saveTelegramDialogs(
                            TelegramDialogsRequest(selectedDialogs: picked))
                    }, onSuccess: { await reload() })
                } label: {
                    Label("保存选择（\(selected.count)）", systemImage: "square.and.arrow.down")
                }
                JSONInspector(value: value)
            } footer: {
                Text("只有被选中的会话会被监听并触发自动转存。")
            }
            .task(id: value) {
                var initial: Set<String> = []
                let responseSelected = value["dialogs"].deepFirst(
                    of: "selected_dialogs", "selected", "monitored").array ?? []
                for item in savedDialogs + responseSelected {
                    initial.insert(Self.identifier(item))
                }
                for dialog in dialogs where dialog.first(of: "selected", "monitored").bool == true {
                    initial.insert(Self.identifier(dialog))
                }
                selected = initial
            }
        }
        .actionFeedback(runner)
    }

    /// 会话头像：服务端把 Telegram 头像缓存成文件，走 `/api/telegram-notify/avatar/{filename}`。
    @ViewBuilder
    private func avatar(_ dialog: JSONValue) -> some View {
        let url = Self.avatarURL(dialog, session: session)
        RemoteImage(url: url, placeholderIcon: "person.crop.circle")
            .frame(width: 32, height: 32)
            .clipShape(Circle())
    }

    static func avatarURL(_ dialog: JSONValue, session: AppSession) -> URL? {
        guard let raw = dialog.first(
            of: "avatar_url", "avatar", "avatar_file", "avatar_filename", "photo").displayString,
              !raw.isEmpty else { return nil }
        if raw.hasPrefix("http") { return URL(string: raw) }
        if raw.hasPrefix("/") { return session.absoluteURL(raw) }
        let filename = raw.split(separator: "/").last.map(String.init) ?? raw
        return try? session.api?.notify.getTelegramAvatarURL(filename: filename)
    }

    static func identifier(_ dialog: JSONValue) -> String {
        dialog.first(of: "id", "chat_id", "peer_id", "dialog_id").displayString
            ?? dialog.displayString ?? ""
    }

    static func mergedDialogs(loaded: [JSONValue], saved: [JSONValue]) -> [JSONValue] {
        var orderedIDs: [String] = []
        var dialogsByID: [String: JSONValue] = [:]

        for dialog in saved + loaded {
            let id = identifier(dialog)
            guard !id.isEmpty else { continue }
            if dialogsByID[id] == nil { orderedIDs.append(id) }
            if var fields = dialogsByID[id]?.object, let newFields = dialog.object {
                fields.merge(newFields) { _, new in new }
                dialogsByID[id] = .object(fields)
            } else {
                dialogsByID[id] = dialog
            }
        }
        return orderedIDs.compactMap { dialogsByID[$0] }
    }
}

/// 企业微信通知。
struct WechatNotifyView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var enabled = false
    @State private var name = "微信"
    @State private var channelName = ""
    @State private var corpID = ""
    @State private var appSecret = ""
    @State private var token = ""
    @State private var agentID = ""
    @State private var proxyURL = ""
    @State private var aesKey = ""
    @State private var whitelist = ""
    @State private var notifyTypes: [String: Bool] = [:]
    @State private var templates: JSONValue = .object([:])
    @State private var defaultTemplates: JSONValue = .object([:])
    @State private var testMessage = "CineChill 测试消息"

    var body: some View {
        RemoteList(title: "企业微信") {
            let api = try session.requireAPI()
            async let configRequest = Probe.json { try await api.notify.getWechatNotifyConfig() }
            async let typesRequest = Probe.json { try await api.notify.getNotificationTypes() }
            async let defaultsRequest = Probe.json { try await api.notify.getNotificationDefaultTemplates() }
            let unifiedTypes = await typesRequest
            let types: JSONValue
            if NotificationSettingsData.typeDefinitions(from: unifiedTypes).isEmpty {
                types = await Probe.json { try await api.notify.getWechatNotificationTypes() }
            } else {
                types = unifiedTypes
            }
            let (config, defaults) = await (configRequest, defaultsRequest)
            return JSONValue.object(["config": config, "types": types, "defaults": defaults])
        } content: { value, reload in
            Section("基础") {
                Toggle("启用", isOn: $enabled)
                TextField("渠道名称", text: $name)
                TextField("显示名称", text: $channelName)
            }

            Section("应用凭据") {
                TextField("企业 ID（CorpID）", text: $corpID)
                    .textInputAutocapitalization(.never)
                TextField("应用 AgentID", text: $agentID)
                    .textInputAutocapitalization(.never)
                SecureField("应用 Secret", text: $appSecret)
                SecureField("回调 Token", text: $token)
                SecureField("EncodingAESKey", text: $aesKey)
            }

            Section("高级") {
                TextField("代理地址（可选）", text: $proxyURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("管理员白名单（逗号分隔）", text: $whitelist)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("测试") {
                TextField("测试内容", text: $testMessage)
                Button {
                    runner.run("已发送") {
                        let api = try session.requireAPI()
                        return try await api.notify.sendWechatTestMessage(message: testMessage)
                    }
                } label: {
                    Label("发送测试消息", systemImage: "paperplane")
                }
                Button {
                    runner.run("测试完成") {
                        let api = try session.requireAPI()
                        return try await api.notify.testWechatNotify()
                    }
                } label: {
                    Label("测试通知配置", systemImage: "bolt.horizontal")
                }
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
                Text("Secret、Token、AESKey 留空表示保留服务器上已有的值。回调地址需要在企业微信后台填写为 CineChill 的 /api/wechat-notify/callback。")
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
        channelName = config.deepFirst(of: "channel_name").string ?? channelName
        corpID = config.deepFirst(of: "corp_id").displayString ?? corpID
        agentID = config.deepFirst(of: "agent_id").displayString ?? agentID
        proxyURL = config.deepFirst(of: "proxy_url").string ?? proxyURL
        whitelist = config.deepFirst(of: "admin_whitelist").string ?? whitelist
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
            return try await api.notify.saveWechatNotifyConfig(
                WechatNotifyConfigModel(enabled: enabled, name: name, channelName: channelName,
                                        corpId: corpID, appSecret: appSecret, token: token,
                                        agentId: agentID, proxyUrl: proxyURL,
                                        encodingAesKey: aesKey, adminWhitelist: whitelist,
                                        notifyTypes: NotificationSettingsData.notifyTypeJSON(notifyTypes),
                                        templates: templates))
        }, onSuccess: {
            appSecret = ""
            token = ""
            aesKey = ""
            await reload()
        })
    }
}
