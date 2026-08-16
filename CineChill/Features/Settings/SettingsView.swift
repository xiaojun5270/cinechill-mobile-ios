import SwiftUI

/// 设置标签页：账号、服务器、302、通知、AI、资源、升级。
struct SettingsView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var lock: AppLock
    @EnvironmentObject private var notifier: TaskNotifier
    @AppStorage(chromeStyleKey) private var chromeRaw = ChromeStyle.liquidGlass.rawValue

    private var chromeTitle: String {
        (ChromeStyle(rawValue: chromeRaw) ?? .liquidGlass).title
    }

    private var lockSubtitle: String {
        lock.isEnabled ? "已开启 · \(lock.availability.title)" : "未开启"
    }

    private var notifySubtitle: String {
        guard notifier.isEnabled else { return "未开启" }
        return notifier.backgroundEnabled ? "已开启 · 含后台检查" : "已开启 · 仅前台"
    }

    var body: some View {
        List {
            Section("账号") {
                ModuleRow(title: "当前账号",
                          subtitle: session.displayUsername,
                          systemImage: "person.crop.circle",
                          tint: .blue) { AccountView() }
                ModuleRow(title: "服务器",
                          subtitle: session.activeServer?.baseURLString ?? "未配置",
                          systemImage: "server.rack",
                          tint: .indigo) { ServerListView() }
            }

            Section("这台设备") {
                ModuleRow(title: "全部功能",
                          subtitle: "\(ModuleIndex.all.count) 个页面，可搜索与收藏",
                          systemImage: "square.grid.3x3.square",
                          tint: .blue) { ModuleSearchView() }
                ModuleRow(title: "外观",
                          subtitle: "导航栏：\(chromeTitle)",
                          systemImage: "paintbrush.pointed",
                          tint: .indigo) { AppearanceView() }
                ModuleRow(title: "应用锁",
                          subtitle: lockSubtitle,
                          systemImage: "faceid",
                          tint: .green) { AppLockView() }
                ModuleRow(title: "任务通知",
                          subtitle: notifySubtitle,
                          systemImage: "bell.badge",
                          tint: .red) { TaskNotifyView() }
            }

            Section("服务端配置") {
                ModuleRow(title: "302 与网盘",
                          subtitle: "115 账号、Emby 直链、扫描目录",
                          systemImage: "externaldrive.connected.to.line.below",
                          tint: .teal) { Config302View() }
                ModuleRow(title: "服务端参数",
                          subtitle: "config.json 全量编辑与重启",
                          systemImage: "slider.horizontal.3",
                          tint: .gray) { ServerConfigView() }
                ModuleRow(title: "通知渠道",
                          subtitle: "Telegram、企业微信",
                          systemImage: "bell.badge",
                          tint: .orange) { NotifyView() }
            }

            Section("智能与素材") {
                ModuleRow(title: "AI 助手",
                          subtitle: "剧集识别、记忆、提醒、工具权限",
                          systemImage: "sparkles",
                          tint: .purple) { AIAssistantView() }
                ModuleRow(title: "资源与模板",
                          subtitle: "字体、布局、模板、译名、套件",
                          systemImage: "paintpalette",
                          tint: .pink) { ResourcesView() }
            }

            Section("维护") {
                ModuleRow(title: "版本升级",
                          subtitle: session.serverVersion.map { "服务端 \($0)" } ?? "检查更新",
                          systemImage: "arrow.up.circle",
                          tint: .green) { UpgradeView() }
                ModuleRow(title: "关于",
                          subtitle: "客户端信息与已知限制",
                          systemImage: "info.circle",
                          tint: .gray) { AboutView() }
            }
        }
        .navigationTitle("设置")
    }
}

/// 账号信息、修改凭据、退出登录。
struct AccountView: View {
    @EnvironmentObject private var session: AppSession
    @State private var oldPassword = ""
    @State private var newUsername = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var working = false
    @State private var message: String?
    @State private var failed = false
    @State private var confirmLogout = false
    @State private var prepared = false

    private var canSubmit: Bool {
        !oldPassword.isEmpty && !newUsername.isEmpty
            && !newPassword.isEmpty && newPassword == confirmPassword && !working
    }

    var body: some View {
        Form {
            Section("当前") {
                KeyValueRow("用户名", session.displayUsername)
                KeyValueRow("服务器", session.activeServer?.baseURLString ?? "—", monospaced: true)
                if let version = session.serverVersion {
                    KeyValueRow("服务端版本", version)
                }
                if session.userInfo.object != nil {
                    JSONInspector(value: session.userInfo)
                }
            }

            Section {
                SecureField("当前密码", text: $oldPassword)
                TextField("新用户名", text: $newUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("新密码", text: $newPassword)
                SecureField("确认新密码", text: $confirmPassword)
                Button {
                    submit()
                } label: {
                    HStack {
                        if working { ProgressView().padding(.trailing, 6) }
                        Text("保存新凭据")
                    }
                }
                .disabled(!canSubmit)
                if !newPassword.isEmpty && newPassword != confirmPassword {
                    Text("两次输入的新密码不一致").font(.footnote).foregroundStyle(.red)
                }
                if let message {
                    Label(message, systemImage: failed ? "xmark.circle" : "checkmark.circle")
                        .font(.footnote)
                        .foregroundStyle(failed ? .red : .green)
                }
            } header: {
                Text("修改登录凭据")
            } footer: {
                Text("修改成功后本机钥匙串中的密码会同步更新，其他设备需要重新登录。")
            }

            Section {
                Button {
                    confirmLogout = true
                } label: {
                    Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("账号")
        .confirmationDialog("退出当前账号？", isPresented: $confirmLogout, titleVisibility: .visible) {
            Button("退出登录", role: .destructive) {
                Task { await session.logout() }
            }
            Button("取消", role: .cancel) {}
        }
        .task {
            guard !prepared else { return }
            prepared = true
            newUsername = session.activeServer?.username ?? ""
        }
    }

    private func submit() {
        working = true
        message = nil
        Task {
            do {
                try await session.changeCredentials(oldPassword: oldPassword,
                                                    newUsername: newUsername,
                                                    newPassword: newPassword)
                failed = false
                message = "已更新凭据"
                oldPassword = ""
                newPassword = ""
                confirmPassword = ""
            } catch {
                failed = true
                message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            working = false
        }
    }
}

/// 服务端升级。
struct UpgradeView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var confirmStart = false

    var body: some View {
        RemoteList(title: "版本升级") {
            let api = try session.requireAPI()
            return try await api.upgrade.upgradeStatus()
        } content: { value, reload in
            Section("状态") {
                KeyValueRow("当前版本", value.deepFirst(of: "current_version", "version"))
                KeyValueRow("最新版本", value.deepFirst(of: "latest_version", "remote_version"))
                KeyValueRow("有新版本", value.deepFirst(of: "has_update", "update_available"))
                KeyValueRow("阶段", value.deepFirst(of: "stage", "status", "state"))
                if let total = value.deepFirst(of: "total").double, total > 0 {
                    let done = value.deepFirst(of: "done", "current", "progress").double ?? 0
                    ProgressView(value: min(done / total, 1))
                }
                if let message = value.deepFirst(of: "message", "detail", "log").displayString {
                    Text(message).font(.caption).foregroundStyle(.secondary).lineLimit(6)
                }
            }

            if let notes = value.deepFirst(of: "changelog", "release_notes", "notes").displayString {
                Section("更新说明") {
                    Text(notes).font(.footnote).textSelection(.enabled)
                }
            }

            Section {
                Button {
                    runner.run("已检查", operation: {
                        let api = try session.requireAPI()
                        return try await api.upgrade.upgradeCheck(UpgradeCheckRequest(force: true))
                    }, onSuccess: { await reload() })
                } label: {
                    Label("检查更新", systemImage: "arrow.triangle.2.circlepath")
                }
                Button {
                    confirmStart = true
                } label: {
                    Label("开始升级", systemImage: "arrow.up.circle")
                }
                .foregroundStyle(.orange)
                JSONInspector(value: value)
            } footer: {
                Text("升级过程中服务端会重启，期间 App 会短暂无法连接。请确认没有正在运行的整理或同步任务。")
            }
            .confirmationDialog("开始升级服务端？", isPresented: $confirmStart, titleVisibility: .visible) {
                Button("开始升级", role: .destructive) {
                    runner.run("已开始升级", operation: {
                        let api = try session.requireAPI()
                        return try await api.upgrade.upgradeStart(UpgradeStartRequest())
                    }, onSuccess: { await reload() })
                }
                Button("取消", role: .cancel) {}
            }
        }
        .actionFeedback(runner)
    }
}

/// 关于：客户端信息与已知限制。
struct AboutView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        List {
            Section("客户端") {
                KeyValueRow("名称", "CineChill for iOS")
                KeyValueRow("界面覆盖", "\(ModuleIndex.all.count) 个页面 / 全量对齐 Web 后台")
                KeyValueRow("最低系统", "iOS 17.0")
                KeyValueRow("导航栏材质", GlassChrome.systemDrawsGlass ? "系统液态玻璃" : "自绘玻璃拟态")
            }
            Section("服务端") {
                KeyValueRow("地址", session.activeServer?.baseURLString ?? "—", monospaced: true)
                KeyValueRow("版本", session.serverVersion ?? "未知")
                KeyValueRow("接口基线", "CineChill UI v1.0.0.43 OpenAPI")
            }
            Section {
                Text("服务端接口未声明响应结构，所有页面都会尽量匹配常见字段名，并在每屏底部提供「原始数据」以便核对实际返回内容。")
                Text("若某个字段显示为「—」，说明服务端返回的键名与预期不同，可从原始数据中确认后反馈。")
            } header: {
                Text("已知限制")
            }
            Section {
                Text("允许自签名证书是按服务器单独开启的选项，开启后该主机不再校验 HTTPS 证书，仅建议在可信局域网内使用。")
                Text("应用锁使用系统 Face ID / Touch ID，只挡本机界面；服务端接口本身仍依赖账号密码鉴权。")
                Text("后台任务检查由系统按使用习惯调度，间隔可能从十几分钟到数小时；需要准确时间请在前台手动检查。")
            } header: {
                Text("安全提示")
            }
        }
        .navigationTitle("关于")
    }
}
