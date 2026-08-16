import SwiftUI

/// 302 与网盘：115 账号、Emby 直链、维护操作。
struct Config302View: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    var body: some View {
        RemoteList(title: "302 与网盘") {
            let api = try session.requireAPI()
            return try await api.config302.getConfig302()
        } content: { value, reload in
            let config = Self.unwrap(value)
            let drives = config["drives"].array ?? []
            let embys = config["embys"].array ?? []

            Section("115 账号（\(drives.count)）") {
                if drives.isEmpty { EmptyRow("还没有配置 115 账号") }
                ForEach(Array(drives.enumerated()), id: \.offset) { index, drive in
                    NavigationLink {
                        Drive115EditorView(config: config, index: index, reload: reload)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(drive.first(of: "name").displayString ?? "网盘 #\(index)")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                StatusBadge(drive.first(of: "cookie").string?.isEmpty == false ? "已登录" : "未登录",
                                            tone: drive.first(of: "cookie").string?.isEmpty == false ? .good : .warning)
                            }
                            Text("上传目录 " + (drive.first(of: "upload_dir").displayString ?? "—"))
                                .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                }
                NavigationLink {
                    Drive115EditorView(config: config, index: nil, reload: reload)
                } label: {
                    Label("添加 115 账号", systemImage: "plus.circle")
                }
            }

            Section("Emby 直链（\(embys.count)）") {
                if embys.isEmpty { EmptyRow("还没有配置 Emby") }
                ForEach(Array(embys.enumerated()), id: \.offset) { index, emby in
                    NavigationLink {
                        Emby302EditorView(config: config, index: index, reload: reload)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(emby.first(of: "name").displayString ?? "Emby #\(index)")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                StatusBadge(emby.first(of: "enabled").bool == false ? "停用" : "启用",
                                            tone: emby.first(of: "enabled").bool == false ? .neutral : .good)
                            }
                            Text(emby.first(of: "url").displayString ?? "—")
                                .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                }
                NavigationLink {
                    Emby302EditorView(config: config, index: nil, reload: reload)
                } label: {
                    Label("添加 Emby", systemImage: "plus.circle")
                }
            }

            Section("登录与校验") {
                NavigationLink {
                    Qrcode115LoginView(config: config, reload: reload)
                } label: {
                    Label("115 扫码登录", systemImage: "qrcode")
                }
                NavigationLink {
                    Cookie115TestView()
                } label: {
                    Label("测试 115 Cookie", systemImage: "checkmark.shield")
                }
            }

            Section("维护操作") {
                Button {
                    runner.run("已触发清理") {
                        let api = try session.requireAPI()
                        return try await api.config302.manualCleanup(ManualCleanupPayload())
                    }
                } label: {
                    Label("手动清理回收站", systemImage: "trash")
                }
                Button {
                    runner.run("已触发签到") {
                        let api = try session.requireAPI()
                        return try await api.config302.manualSigninAll()
                    }
                } label: {
                    Label("全部账号手动签到", systemImage: "checkmark.seal")
                }
                NavigationLink {
                    StandardTopologyView()
                } label: {
                    Label("创建标准目录结构", systemImage: "folder.badge.gearshape")
                }
            }

            Section {
                NavigationLink {
                    Config302RawView()
                } label: {
                    Label("原始配置编辑", systemImage: "curlybraces")
                }
                JSONInspector(value: value)
            } footer: {
                Text("115 Cookie 属于敏感凭据，仅在本机与你的 CineChill 服务器之间传输。表单中默认不回显完整内容。")
            }
        }
        .actionFeedback(runner)
    }

    /// GET /api/302/config 可能直接返回配置，也可能包一层 config/data。
    static func unwrap(_ value: JSONValue) -> JSONValue {
        if value["drives"].array != nil || value["embys"].array != nil { return value }
        for key in ["config", "data", "settings"] {
            let inner = value[key]
            if inner["drives"].array != nil || inner["embys"].array != nil { return inner }
        }
        return value
    }

    static func payload(from config: JSONValue) -> Config302Payload {
        (try? config.decoded(Config302Payload.self)) ?? Config302Payload()
    }
}

/// 单个 115 账号编辑。
struct Drive115EditorView: View {
    let config: JSONValue
    let index: Int?
    let reload: Reload

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var runner = ActionRunner()
    @State private var draft = Drive115Config()
    @State private var cookieInput = ""
    @State private var prepared = false
    @State private var confirmDelete = false

    private var isNew: Bool { index == nil }

    var body: some View {
        Form {
            Section("基本") {
                TextField("名称", text: $draft.name)
                TextField("上传目录", text: $draft.uploadDir)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Stepper("转存网盘序号 \(draft.transferDriveIndex)", value: $draft.transferDriveIndex, in: 0...9)
                TextField("转存目录", text: $draft.transferDir)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section {
                SecureField(draft.cookie.isEmpty ? "粘贴 Cookie" : "重新粘贴以替换", text: $cookieInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !draft.cookie.isEmpty {
                    KeyValueRow("当前状态", "已保存 Cookie（\(draft.cookie.count) 字符）")
                }
                Button {
                    runner.run("Cookie 可用") {
                        let api = try session.requireAPI()
                        let cookie = cookieInput.isEmpty ? draft.cookie : cookieInput
                        return try await api.config302.test115Cookie(Test115Payload(cookie: cookie))
                    }
                } label: {
                    Label("测试 Cookie", systemImage: "bolt.horizontal")
                }
                .disabled(cookieInput.isEmpty && draft.cookie.isEmpty)
            } header: {
                Text("Cookie")
            } footer: {
                Text("留空表示保留服务器上已有的 Cookie。也可以在上一页用「115 扫码登录」自动写入。")
            }

            Section("回收站与同步") {
                Toggle("启用同步", isOn: $draft.enableSync)
                Toggle("自动清空回收站", isOn: $draft.autoDelete)
                TextField("清理 Cron", text: $draft.deleteCron)
                    .textInputAutocapitalization(.never)
                Text(Fmt.cron(draft.deleteCron)).font(.caption).foregroundStyle(.secondary)
                SecureField("回收站密码", text: $draft.recycleCode)
            }

            Section("标准目录结构") {
                Toggle("启用标准拓扑", isOn: $draft.enableStandardTopology)
                TextField("本地媒体根目录", text: $draft.localMediaRoot)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("网盘根目录名", text: $draft.remoteRootName)
            }

            Section {
                Button(isNew ? "创建账号" : "保存修改") { save() }
                    .disabled(draft.name.isEmpty)
                if !isNew {
                    Button("删除此账号") { confirmDelete = true }
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(isNew ? "添加 115 账号" : "编辑 115 账号")
        .actionFeedback(runner)
        .confirmationDialog("删除该 115 账号？", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("删除", role: .destructive) { deleteDrive() }
            Button("取消", role: .cancel) {}
        }
        .task {
            guard !prepared else { return }
            prepared = true
            let payload = Config302View.payload(from: config)
            if let index, index < payload.drives.count {
                draft = payload.drives[index]
            }
        }
    }

    private func save() {
        runner.run("已保存", operation: {
            let api = try session.requireAPI()
            var payload = Config302View.payload(from: config)
            var drive = draft
            if !cookieInput.isEmpty { drive.cookie = cookieInput }
            if let index, index < payload.drives.count {
                payload.drives[index] = drive
            } else {
                payload.drives.append(drive)
            }
            return try await api.config302.saveConfig302(payload)
        }, onSuccess: {
            cookieInput = ""
            await reload()
            dismiss()
        })
    }

    private func deleteDrive() {
        guard let index else { return }
        runner.run("已删除", operation: {
            let api = try session.requireAPI()
            var payload = Config302View.payload(from: config)
            guard index < payload.drives.count else { return .object(["success": .bool(false)]) }
            payload.drives.remove(at: index)
            return try await api.config302.saveConfig302(payload)
        }, onSuccess: {
            await reload()
            dismiss()
        })
    }
}
