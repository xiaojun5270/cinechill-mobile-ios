import SwiftUI
import UniformTypeIdentifiers

/// Emby 用户管理：列表、新增、禁用、改密、删除、绑定。
struct EmbyUsersView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var creating = false

    var body: some View {
        RemoteList(title: "Emby 用户") {
            let api = try session.requireAPI()
            return try await api.embyUsers.listEmbyUsers()
        } content: { value, reload in
            let users = value.list("users", "Items")
            if users.isEmpty {
                EmptyRow("没有读取到用户")
            }
            ForEach(Array(users.enumerated()), id: \.offset) { _, user in
                NavigationLink {
                    EmbyUserDetailView(user: user, reload: reload)
                } label: {
                    row(user)
                }
            }
            Section {
                Button {
                    creating = true
                } label: {
                    Label("新增用户", systemImage: "person.badge.plus")
                }
            }
            .sheet(isPresented: $creating) {
                NavigationStack {
                    EmbyUserCreateView(users: users) { reload.fire() }
                }
            }
        }
        .actionFeedback(runner)
    }

    private func row(_ user: JSONValue) -> some View {
        let disabled = user.deepFirst(of: "IsDisabled", "is_disabled", "disabled").bool ?? false
        return HStack(spacing: 10) {
            RemoteImage(url: avatarURL(user), placeholderIcon: "person.crop.circle")
                .frame(width: 34, height: 34)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(user.first(of: "Name", "name").displayString ?? "—")
                if let last = user.first(of: "LastActivityDate", "last_activity").displayString {
                    Text("最近活动 " + Fmt.relative(.string(last)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if disabled { StatusBadge("已禁用", tone: .bad) }
        }
    }

    private func avatarURL(_ user: JSONValue) -> URL? {
        guard let id = user.first(of: "Id", "id", "user_id").displayString else { return nil }
        let tag = user.deepFirst(of: "PrimaryImageTag", "image_tag").string
        return try? session.api?.embyUsers.getEmbyUserAvatarURL(userId: id, tag: tag)
    }
}

/// 用户详情与操作。进入页面后单独调用 `GET /api/emby/users/{user_id}` 拿服务端最新数据，
/// 列表里的字段只用来做标题与兜底。
struct EmbyUserDetailView: View {
    let user: JSONValue
    let reload: Reload

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var newPassword = ""
    @State private var showDeleteConfirm = false
    @State private var importingAvatar = false
    /// 上传头像后用它做缓存击穿（`RemoteImage` 按 URL 缓存）。
    @State private var avatarStamp = ""

    private var userID: String {
        user.first(of: "Id", "id", "user_id").displayString ?? ""
    }

    private var titleText: String {
        user.first(of: "Name", "name").displayString ?? "用户"
    }

    var body: some View {
        RemoteList(title: titleText, cacheKey: "emby-user-\(userID)") {
            let api = try session.requireAPI()
            return try await api.embyUsers.getEmbyUser(userId: userID)
        } content: { detail, detailReload in
            let info = Self.normalized(detail, fallback: user)
            accountSection(info)
            avatarSection(info, detailReload: detailReload)
            actionSection(info, detailReload: detailReload)
            editSection(info, detailReload: detailReload)
            passwordSection()
            deleteSection()
            Section("全部字段") { JSONFieldList(value: info) }
            Section { JSONInspector(value: detail, title: "接口返回") }
        }
        .actionFeedback(runner)
        .confirmationDialog("删除该 Emby 用户？此操作不可恢复。",
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                runner.run("已删除", operation: {
                    let api = try session.requireAPI()
                    return try await api.embyUsers.deleteEmbyUser(userId: userID)
                }, onSuccess: { await reload() })
            }
            Button("取消", role: .cancel) {}
        }
    }

    /// 详情接口可能直接返回 Emby 用户对象，也可能包一层 `user`/`data`。
    private static func normalized(_ detail: JSONValue, fallback: JSONValue) -> JSONValue {
        if !detail.first(of: "Name", "name").isNull { return detail }
        for key in ["user", "data", "result", "item"] where detail[key].object != nil {
            return detail[key]
        }
        return detail.object == nil ? fallback : detail
    }

    private func disabledFlag(_ info: JSONValue) -> Bool {
        info.deepFirst(of: "IsDisabled", "is_disabled", "disabled").bool
            ?? user.deepFirst(of: "IsDisabled", "is_disabled", "disabled").bool
            ?? false
    }

    private func avatarURL(_ info: JSONValue) -> URL? {
        guard !userID.isEmpty else { return nil }
        let tag: String? = avatarStamp.isEmpty
            ? info.deepFirst(of: "PrimaryImageTag", "image_tag").string
            : avatarStamp
        return try? session.api?.embyUsers.getEmbyUserAvatarURL(userId: userID, tag: tag)
    }

    @ViewBuilder
    private func accountSection(_ info: JSONValue) -> some View {
        Section("账号") {
            KeyValueRow("名称", info.first(of: "Name", "name"))
            KeyValueRow("ID", userID, monospaced: true)
            KeyValueRow("状态", disabledFlag(info) ? "已禁用" : "正常")
            if let server = info.first(of: "ServerName", "server_name").displayString {
                KeyValueRow("所属服务器", server)
            }
            if let last = info.first(of: "LastActivityDate", "last_activity").displayString {
                KeyValueRow("最近活动", Fmt.dateTime(.string(last)))
            }
        }
    }

    @ViewBuilder
    private func avatarSection(_ info: JSONValue, detailReload: Reload) -> some View {
        Section("头像") {
            HStack(spacing: 12) {
                RemoteImage(url: avatarURL(info), placeholderIcon: "person.crop.circle")
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                Text("选择图片后立即上传到 Emby，替换当前头像。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button {
                importingAvatar = true
            } label: {
                Label("从「文件」上传头像", systemImage: "photo.badge.plus")
            }
            .disabled(userID.isEmpty)
        }
        .fileImporter(isPresented: $importingAvatar, allowedContentTypes: [.image]) { result in
            switch result {
            case .success(let url):
                uploadAvatar(url, detailReload: detailReload)
            case .failure:
                break
            }
        }
    }

    private func uploadAvatar(_ url: URL, detailReload: Reload) {
        runner.run("头像已更新", operation: {
            let api = try session.requireAPI()
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let mime = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
                ?? "image/jpeg"
            return try await api.embyUsers.uploadEmbyUserAvatar(
                userId: userID, fileData: data,
                filename: url.lastPathComponent, mimeType: mime)
        }, onSuccess: {
            avatarStamp = String(Int(Date().timeIntervalSince1970))
            await detailReload()
            await reload()
        })
    }

    @ViewBuilder
    private func actionSection(_ info: JSONValue, detailReload: Reload) -> some View {
        let disabled = disabledFlag(info)
        Section("操作") {
            Button {
                runner.run(disabled ? "已启用" : "已禁用", operation: {
                    let api = try session.requireAPI()
                    return try await api.embyUsers.setEmbyUserDisabled(
                        userId: userID, EmbyUserDisabledPayload(disabled: !disabled))
                }, onSuccess: {
                    await detailReload()
                    await reload()
                })
            } label: {
                Label(disabled ? "启用账号" : "禁用账号",
                      systemImage: disabled ? "person.fill.checkmark" : "person.fill.xmark")
            }
            Button {
                runner.run("已绑定", operation: {
                    let api = try session.requireAPI()
                    return try await api.embyUsers.bindEmbyUser(userId: userID)
                }, onSuccess: {
                    await detailReload()
                    await reload()
                })
            } label: {
                Label("绑定到 CineChill", systemImage: "link")
            }
        }
    }

    @ViewBuilder
    private func editSection(_ info: JSONValue, detailReload: Reload) -> some View {
        Section("资料") {
            NavigationLink {
                EmbyUserEditView(userID: userID, detail: info) {
                    await detailReload()
                    await reload()
                }
            } label: {
                Label("编辑名称与权限", systemImage: "square.and.pencil")
            }
        }
    }

    @ViewBuilder
    private func passwordSection() -> some View {
        Section("重置密码") {
            SecureField("新密码", text: $newPassword)
            Button("提交重置") {
                runner.run("密码已重置", operation: {
                    let api = try session.requireAPI()
                    return try await api.embyUsers.resetEmbyUserPassword(
                        userId: userID,
                        EmbyUserPasswordPayload(newPassword: newPassword))
                }, onSuccess: {
                    newPassword = ""
                })
            }
            .disabled(newPassword.count < 4)
        }
    }

    @ViewBuilder
    private func deleteSection() -> some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("删除用户", systemImage: "trash")
            }
        }
    }
}

/// 编辑 Emby 用户：名称 + Policy（权限）+ Configuration（偏好）。
/// 服务端只接受完整的 Policy / Configuration 对象，因此这里直接拿详情返回的对象做逐字段编辑，
/// 详情里没有的字段不会凭空补上（保持为 nil，请求体里就不带该键）。
struct EmbyUserEditView: View {
    let userID: String
    let onSaved: () async -> Void

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var name: String
    @State private var policy: JSONValue
    @State private var configuration: JSONValue

    init(userID: String, detail: JSONValue, onSaved: @escaping () async -> Void) {
        self.userID = userID
        self.onSaved = onSaved
        _name = State(initialValue: detail.first(of: "Name", "name").displayString ?? "")
        _policy = State(initialValue: detail.first(of: "Policy", "policy"))
        _configuration = State(initialValue: detail.first(of: "Configuration", "configuration"))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var draft: JSONValue {
        .object(["name": .string(trimmedName), "policy": policy, "configuration": configuration])
    }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("用户名", text: $name)
                    .textInputAutocapitalization(.never)
            }
            Section("权限 Policy") {
                if policy.object == nil {
                    EmptyRow("详情未返回 Policy，保存时不会提交该字段")
                } else {
                    JSONObjectEditor(value: $policy)
                }
            }
            Section("偏好 Configuration") {
                if configuration.object == nil {
                    EmptyRow("详情未返回 Configuration，保存时不会提交该字段")
                } else {
                    JSONObjectEditor(value: $configuration)
                }
            }
            Section {
                Button {
                    save()
                } label: {
                    Label("保存修改", systemImage: "square.and.arrow.down")
                }
                .disabled(trimmedName.isEmpty)
                JSONInspector(value: draft, title: "当前草稿")
            }
        }
        .navigationTitle("编辑用户")
        .actionFeedback(runner)
    }

    private func save() {
        runner.run("已保存", operation: {
            let api = try session.requireAPI()
            return try await api.embyUsers.updateEmbyUser(
                userId: userID,
                EmbyUserUpdatePayload(name: trimmedName,
                                      policy: policy.object == nil ? nil : policy,
                                      configuration: configuration.object == nil ? nil : configuration))
        }, onSuccess: { await onSaved() })
    }
}

/// 新增 Emby 用户。
struct EmbyUserCreateView: View {
    let users: [JSONValue]
    let onCreated: () -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var runner = ActionRunner()
    @State private var name = ""
    @State private var password = ""
    @State private var templateID = ""

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("用户名", text: $name)
                    .textInputAutocapitalization(.never)
                SecureField("初始密码（可留空）", text: $password)
            }
            Section("按模板创建") {
                Picker("模板用户", selection: $templateID) {
                    Text("不使用模板").tag("")
                    ForEach(Array(users.enumerated()), id: \.offset) { _, user in
                        let id = user.first(of: "Id", "id").displayString ?? ""
                        Text(user.first(of: "Name", "name").displayString ?? id).tag(id)
                    }
                }
            }
            Section {
                Button("创建") {
                    runner.run("已创建", operation: {
                        let api = try session.requireAPI()
                        return try await api.embyUsers.createEmbyUser(
                            EmbyUserCreatePayload(name: name, templateUserId: templateID, password: password))
                    }, onSuccess: {
                        onCreated()
                        dismiss()
                    })
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("新增用户")
        .actionFeedback(runner)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }
        }
    }
}
