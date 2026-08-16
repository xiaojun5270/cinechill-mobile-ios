import SwiftUI

/// 115 网盘清理：任务列表 + 目录选择。
struct Cleanup115View: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var creating = false
    @State private var editing: CleanupTaskDraft?

    var body: some View {
        RemoteList(title: "115 清理") {
            let api = try session.requireAPI()
            return try await api.cleanup115.getTasks()
        } content: { value, reload in
            let tasks = value.list("tasks", "items")
            if tasks.isEmpty { EmptyRow("还没有清理任务") }
            ForEach(Array(tasks.enumerated()), id: \.offset) { _, task in
                taskRow(task, reload: reload)
            }
            Section {
                Button {
                    creating = true
                } label: {
                    Label("新增清理任务", systemImage: "plus.circle")
                }
            } footer: {
                Text("清理任务按 Cron 周期扫描指定的 115 目录，删除重复或失效文件，可选同时清空回收站。")
            }
            .sheet(isPresented: $creating) {
                NavigationStack { CleanupTaskEditorView(draft: CleanupTaskDraft()) { reload.fire() } }
            }
            .sheet(item: $editing) { draft in
                NavigationStack { CleanupTaskEditorView(draft: draft) { reload.fire() } }
            }
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func taskRow(_ task: JSONValue, reload: Reload) -> some View {
        let id = task.first(of: "id", "task_id").displayString ?? ""
        let enabled = task.first(of: "enabled").bool ?? true
        let folders = task.list("folders")
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(task.first(of: "name").displayString ?? "—")
                    .font(.subheadline.weight(.medium))
                Spacer()
                StatusBadge(enabled ? "已启用" : "已停用", tone: enabled ? .good : .neutral)
            }
            HStack(spacing: 8) {
                Text(Fmt.cron(task.first(of: "cron").string))
                Text("· \(folders.count) 个目录")
                if task.first(of: "clear_recycle_bin").bool == true { Text("· 清回收站") }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            if let last = task.first(of: "last_run_at", "last_run").displayString {
                Text("上次运行 " + Fmt.relative(.string(last)))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                Button("立即运行") {
                    runner.run("已触发", operation: {
                        let api = try session.requireAPI()
                        return try await api.cleanup115.runTask(taskId: id)
                    }, onSuccess: { await reload() })
                }
                Button(enabled ? "停用" : "启用") {
                    runner.run("已更新", operation: {
                        let api = try session.requireAPI()
                        return try await api.cleanup115.toggleTask(taskId: id, TogglePayload(enabled: !enabled))
                    }, onSuccess: { await reload() })
                }
                Button("编辑") { editing = CleanupTaskDraft(task) }
                Button("删除") {
                    runner.run("已删除", operation: {
                        let api = try session.requireAPI()
                        return try await api.cleanup115.deleteTask(taskId: id)
                    }, onSuccess: { await reload() })
                }
                .foregroundStyle(.red)
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .disabled(id.isEmpty)
        }
    }
}

/// 清理目录条目（可编辑草稿）。
struct CleanupFolderDraft: Identifiable, Hashable {
    var id = UUID()
    var cid: String
    var name: String
    var path: String

    init(cid: String = "", name: String = "", path: String = "") {
        self.cid = cid
        self.name = name
        self.path = path
    }

    init(_ value: JSONValue) {
        cid = value.first(of: "cid").displayString ?? ""
        name = value.first(of: "name").string ?? ""
        path = value.first(of: "path").string ?? ""
    }

    var model: CleanupFolder { CleanupFolder(cid: cid, name: name, path: path) }
}

struct CleanupTaskDraft: Identifiable {
    var id: String
    var name: String
    var cron: String
    var enabled: Bool
    var clearRecycleBin: Bool
    var folders: [CleanupFolderDraft]

    init() {
        id = ""
        name = ""
        cron = "0 4 * * *"
        enabled = true
        clearRecycleBin = true
        folders = []
    }

    init(_ task: JSONValue) {
        id = task.first(of: "id", "task_id").displayString ?? ""
        name = task.first(of: "name").string ?? ""
        cron = task.first(of: "cron").string ?? "0 4 * * *"
        enabled = task.first(of: "enabled").bool ?? true
        clearRecycleBin = task.first(of: "clear_recycle_bin").bool ?? true
        folders = task.list("folders").map(CleanupFolderDraft.init)
    }
}

struct CleanupTaskEditorView: View {
    @State var draft: CleanupTaskDraft
    let onSaved: () -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var runner = ActionRunner()
    @State private var picking = false

    private var isNew: Bool { draft.id.isEmpty }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("任务名称", text: $draft.name)
                TextField("Cron 表达式", text: $draft.cron)
                    .textInputAutocapitalization(.never)
                Text(Fmt.cron(draft.cron)).font(.caption).foregroundStyle(.secondary)
                Toggle("清空回收站", isOn: $draft.clearRecycleBin)
                Toggle("启用", isOn: $draft.enabled)
            }
            Section("清理目录（\(draft.folders.count)）") {
                if draft.folders.isEmpty {
                    Text("尚未选择目录").font(.footnote).foregroundStyle(.secondary)
                }
                ForEach($draft.folders) { $folder in
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("目录名称", text: $folder.name)
                        TextField("CID", text: $folder.cid)
                            .textInputAutocapitalization(.never)
                            .font(.caption)
                        if !folder.path.isEmpty {
                            Text(folder.path).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
                .onDelete { draft.folders.remove(atOffsets: $0) }
                Button {
                    picking = true
                } label: {
                    Label("从 115 选择目录", systemImage: "folder.badge.plus")
                }
                Button {
                    draft.folders.append(CleanupFolderDraft())
                } label: {
                    Label("手动添加 CID", systemImage: "plus")
                }
            }
            Section {
                Button(isNew ? "创建任务" : "保存修改") { save() }
                    .disabled(draft.name.isEmpty || draft.folders.isEmpty)
            }
        }
        .navigationTitle(isNew ? "新增清理任务" : "编辑清理任务")
        .actionFeedback(runner)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
        }
        .sheet(isPresented: $picking) {
            NavigationStack {
                Drive115BrowserView { picked in
                    draft.folders.append(picked)
                }
            }
        }
    }

    private func save() {
        runner.run("已保存", operation: {
            let api = try session.requireAPI()
            let payload = CleanupTaskPayload(name: draft.name, cron: draft.cron,
                                             enabled: draft.enabled,
                                             clearRecycleBin: draft.clearRecycleBin,
                                             folders: draft.folders.map(\.model))
            if isNew { return try await api.cleanup115.createTask(payload) }
            return try await api.cleanup115.updateTask(taskId: draft.id, payload)
        }, onSuccess: {
            onSaved()
            dismiss()
        })
    }
}
