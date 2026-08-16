import SwiftUI

struct UploadTaskDraft: Identifiable {
    var raw: JSONValue
    var id: String
    var name: String
    var enabled: Bool
    var localFolder: String
    var targetCID: String
    var targetName: String
    var targetPath: String
    var watchMode: String
    var includeExisting: Bool
    var deleteLocal: Bool
    var deleteDownloaderAfterAllUploaded: Bool
    var skipWhenNoRapid: Bool

    init() {
        raw = .object([:])
        id = ""
        name = ""
        enabled = true
        localFolder = ""
        targetCID = ""
        targetName = ""
        targetPath = ""
        watchMode = "realtime"
        includeExisting = true
        deleteLocal = false
        deleteDownloaderAfterAllUploaded = false
        skipWhenNoRapid = false
    }

    init(_ task: JSONValue) {
        raw = task
        id = task.first(of: "id", "task_id").displayString ?? ""
        name = task.first(of: "name").string ?? ""
        enabled = task.first(of: "enabled").bool ?? true
        localFolder = task.first(of: "local_folder").string ?? ""
        targetCID = task.first(of: "target_cid").displayString ?? ""
        targetName = task.first(of: "target_name").string ?? ""
        targetPath = task.first(of: "target_path").string ?? ""
        let storedMode = task.first(of: "watch_mode").string ?? "realtime"
        watchMode = storedMode == "scan" ? "manual" : storedMode
        includeExisting = task.first(of: "include_existing_on_start").bool ?? true
        deleteLocal = task.first(of: "delete_local_after_success").bool ?? false
        deleteDownloaderAfterAllUploaded = task.first(of: "delete_downloader_after_all_uploaded").bool ?? false
        skipWhenNoRapid = task.first(of: "skip_upload_when_no_rapid_resource").bool ?? false
    }
}

struct UploadTaskEditorView: View {
    @State var draft: UploadTaskDraft
    let onSaved: () -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var runner = ActionRunner()
    @State private var pickingCloud = false
    @State private var pickingLocal = false
    @State private var confirmingDownloaderCleanup = false

    private var isNew: Bool { draft.id.isEmpty }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("任务名称", text: $draft.name)
                Picker("监听模式", selection: $draft.watchMode) {
                    Text("实时监听").tag("realtime")
                    Text("手动扫描").tag("manual")
                }
                Toggle("启用", isOn: $draft.enabled)
            }
            Section("本地目录") {
                TextField("本地路径", text: $draft.localFolder, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    pickingLocal = true
                } label: {
                    Label("浏览服务器目录", systemImage: "folder")
                }
            }
            Section("115 目标目录") {
                TextField("目标 CID", text: $draft.targetCID)
                    .textInputAutocapitalization(.never)
                TextField("目标名称", text: $draft.targetName)
                if !draft.targetPath.isEmpty {
                    Text(draft.targetPath).font(.caption2).foregroundStyle(.tertiary)
                }
                Button {
                    pickingCloud = true
                } label: {
                    Label("从 115 选择目录", systemImage: "externaldrive.badge.plus")
                }
            }
            Section("行为") {
                Toggle("启动时包含已存在文件", isOn: $draft.includeExisting)
                Toggle("上传成功后删除本地文件", isOn: $draft.deleteLocal)
                Toggle("整种完成后清理下载器", isOn: Binding(
                    get: { draft.deleteDownloaderAfterAllUploaded },
                    set: { enabled in
                        if enabled {
                            confirmingDownloaderCleanup = true
                        } else {
                            draft.deleteDownloaderAfterAllUploaded = false
                        }
                    }))
                Toggle("无秒传资源时跳过上传", isOn: $draft.skipWhenNoRapid)
            }
            Section {
                Button(isNew ? "创建任务" : "保存修改") { save() }
                    .disabled(draft.name.isEmpty || draft.localFolder.isEmpty || draft.targetCID.isEmpty)
            } footer: {
                Text("「上传成功后删除本地文件」是不可逆操作，请确认目录无误后再开启。")
            }
        }
        .navigationTitle(isNew ? "新增上传任务" : "编辑上传任务")
        .actionFeedback(runner)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
        }
        .sheet(isPresented: $pickingCloud) {
            NavigationStack {
                Drive115BrowserView { picked in
                    draft.targetCID = picked.cid
                    draft.targetName = picked.name
                    draft.targetPath = picked.path
                }
            }
        }
        .sheet(isPresented: $pickingLocal) {
            NavigationStack {
                LocalFolderBrowserView { path in
                    draft.localFolder = path
                }
            }
        }
        .confirmationDialog("开启整种清理？", isPresented: $confirmingDownloaderCleanup,
                            titleVisibility: .visible) {
            Button("确认开启", role: .destructive) {
                draft.deleteDownloaderAfterAllUploaded = true
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("同一种子的全部目标文件上传完成后，服务端会删除下载器任务及源数据。")
        }
    }

    private func save() {
        runner.run("已保存", operation: {
            let api = try session.requireAPI()
            var fields = draft.raw.object ?? [:]
            fields["name"] = .string(draft.name)
            fields["enabled"] = .bool(draft.enabled)
            fields["local_folder"] = .string(draft.localFolder)
            fields["target_cid"] = .string(draft.targetCID)
            fields["target_name"] = .string(draft.targetName)
            fields["target_path"] = .string(draft.targetPath)
            fields["watch_mode"] = .string(draft.watchMode)
            fields["include_existing_on_start"] = .bool(draft.includeExisting)
            fields["delete_local_after_success"] = .bool(draft.deleteLocal)
            fields["delete_downloader_after_all_uploaded"] = .bool(draft.deleteDownloaderAfterAllUploaded)
            fields["skip_upload_when_no_rapid_resource"] = .bool(draft.skipWhenNoRapid)
            let payload = JSONValue.object(fields)
            return try await api.upload115.saveTaskPreservingFields(
                taskID: isNew ? nil : draft.id,
                body: payload)
        }, onSuccess: {
            onSaved()
            dismiss()
        })
    }
}

/// 服务器本地目录浏览（用于选择上传源目录）。
struct LocalFolderBrowserView: View {
    let onPick: (String) -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var path = "/"
    @State private var entries: [JSONValue] = []
    @State private var loading = false
    @State private var failure: String?

    var body: some View {
        List {
            Section {
                Text(path).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Button {
                    onPick(path)
                    dismiss()
                } label: {
                    Label("选择当前目录", systemImage: "checkmark.circle")
                }
                if path != "/" {
                    Button("上一级") { path = parent(of: path) }
                }
            }
            if loading {
                LoadingRow()
            } else if let failure {
                Section {
                    Text(failure).font(.footnote).foregroundStyle(.red)
                    Button("重试") { Task { await load() } }
                }
            } else {
                Section("子目录（\(entries.count)）") {
                    if entries.isEmpty { EmptyRow("没有子目录") }
                    ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                        let name = entry.first(of: "name", "file_name").displayString ?? "—"
                        let full = entry.first(of: "path", "full_path").string ?? join(path, name)
                        Button {
                            path = full
                        } label: {
                            HStack {
                                Image(systemName: "folder").foregroundStyle(.tint)
                                Text(name).lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("选择本地目录")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
        }
        .task(id: path) { await load() }
    }

    private func parent(of value: String) -> String {
        let trimmed = value.hasSuffix("/") && value != "/" ? String(value.dropLast()) : value
        guard let index = trimmed.lastIndex(of: "/") else { return "/" }
        let result = String(trimmed[trimmed.startIndex..<index])
        return result.isEmpty ? "/" : result
    }

    private func join(_ base: String, _ name: String) -> String {
        base.hasSuffix("/") ? base + name : base + "/" + name
    }

    private func load() async {
        guard let api = session.api else {
            failure = "请先登录服务器"
            return
        }
        loading = true
        failure = nil
        do {
            let value = try await api.upload115.browseLocal(LocalBrowsePayload(path: path))
            let list = value.list("folders", "items", "entries", "dirs")
            entries = list.filter { entry in
                if let isDir = entry.first(of: "is_dir", "isDir", "directory").bool { return isDir }
                return entry.first(of: "type").string != "file"
            }
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            if case .cancelled = error {
                loading = false
                return
            }
            failure = error.errorDescription ?? "读取失败"
        } catch {
            failure = error.localizedDescription
        }
        loading = false
    }
}
