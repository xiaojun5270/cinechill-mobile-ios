import SwiftUI

/// Telegram 账号登录：发送验证码 + 登录。
struct TelegramLoginView: View {
    @State var apiID: String
    @State var apiHash: String
    @State var phone: String

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
    @State private var prepared = false

    var body: some View {
        RemoteList(title: "监听会话") {
            let api = try session.requireAPI()
            return try await api.notify.listTelegramDialogs()
        } content: { value, reload in
            let dialogs = value.list("dialogs", "items", "data", "chats")
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
            .task {
                guard !prepared else { return }
                prepared = true
                let preset = value.list("selected_dialogs", "selected", "monitored")
                for item in preset { selected.insert(Self.identifier(item)) }
                for dialog in dialogs where dialog.first(of: "selected", "monitored").bool == true {
                    selected.insert(Self.identifier(dialog))
                }
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
        guard let raw = dialog.first(of: "avatar", "avatar_file", "avatar_filename", "photo").displayString,
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
    @State private var testMessage = "CineChill 测试消息"

    var body: some View {
        RemoteList(title: "企业微信") {
            let api = try session.requireAPI()
            let config = await Probe.json { try await api.notify.getWechatNotifyConfig() }
            let types = await Probe.json { try await api.notify.getWechatNotificationTypes() }
            return JSONValue.object(["config": config, "types": types])
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

            let types = value["types"].list("types", "items", "data")
            if !types.isEmpty {
                Section("支持的通知类型（\(types.count)）") {
                    ForEach(Array(types.enumerated()), id: \.offset) { _, item in
                        Text(item.first(of: "label", "name", "key").displayString
                             ?? item.string ?? "—")
                            .font(.subheadline)
                    }
                }
            }

            Section {
                Button {
                    save(reload: reload)
                } label: {
                    Label("保存配置", systemImage: "square.and.arrow.down")
                }
                JSONInspector(value: value)
            } footer: {
                Text("Secret、Token、AESKey 留空表示保留服务器上已有的值。回调地址需要在企业微信后台填写为 CineChill 的 /api/notify/wechat/callback。")
            }
            .task { apply(value["config"]) }
        }
        .actionFeedback(runner)
    }

    private func apply(_ config: JSONValue) {
        enabled = config.deepFirst(of: "enabled").bool ?? enabled
        name = config.deepFirst(of: "name").string ?? name
        channelName = config.deepFirst(of: "channel_name").string ?? channelName
        corpID = config.deepFirst(of: "corp_id").displayString ?? corpID
        agentID = config.deepFirst(of: "agent_id").displayString ?? agentID
        proxyURL = config.deepFirst(of: "proxy_url").string ?? proxyURL
        whitelist = config.deepFirst(of: "admin_whitelist").string ?? whitelist
    }

    private func save(reload: Reload) {
        runner.run("已保存", operation: {
            let api = try session.requireAPI()
            return try await api.notify.saveWechatNotifyConfig(
                WechatNotifyConfigModel(enabled: enabled, name: name, channelName: channelName,
                                        corpId: corpID, appSecret: appSecret, token: token,
                                        agentId: agentID, proxyUrl: proxyURL,
                                        encodingAesKey: aesKey, adminWhitelist: whitelist))
        }, onSuccess: {
            appSecret = ""
            token = ""
            aesKey = ""
            await reload()
        })
    }
}
