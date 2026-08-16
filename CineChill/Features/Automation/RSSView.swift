import SwiftUI

/// RSS 模块入口：任务、全局配置、链接生成器、预览。
struct RSSView: View {
    var body: some View {
        List {
            Section {
                ModuleRow(title: "RSS 任务",
                          subtitle: "新增、启停、立即运行",
                          systemImage: "dot.radiowaves.up.forward",
                          tint: .orange) { RSSTasksView() }
                ModuleRow(title: "全局配置",
                          subtitle: "源目录与硬链目录",
                          systemImage: "folder.badge.gearshape",
                          tint: .gray) { RSSConfigView() }
            }
            Section {
                ModuleRow(title: "链接生成器",
                          subtitle: "按预设生成 RSS 地址",
                          systemImage: "link.badge.plus",
                          tint: .blue) { RSSPresetsView() }
                ModuleRow(title: "订阅预览",
                          subtitle: "解析任意 RSS 地址",
                          systemImage: "eye",
                          tint: .teal) { RSSPreviewView() }
            }
        }
        .navigationTitle("RSS 订阅")
    }
}

/// RSS 任务列表。
struct RSSTasksView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var editing: RSSTaskDraft?
    @State private var creating = false

    var body: some View {
        RemoteList(title: "RSS 任务") {
            let api = try session.requireAPI()
            return try await api.rss.getRssTasks()
        } content: { value, reload in
            let tasks = value.list("tasks", "items")
            if tasks.isEmpty { EmptyRow("还没有 RSS 任务") }
            ForEach(Array(tasks.enumerated()), id: \.offset) { _, task in
                taskRow(task, reload: reload)
            }
            Section {
                Button {
                    creating = true
                } label: {
                    Label("新增任务", systemImage: "plus.circle")
                }
            }
            .sheet(isPresented: $creating) {
                NavigationStack {
                    RSSTaskEditorView(draft: RSSTaskDraft()) { reload.fire() }
                }
            }
            .sheet(item: $editing) { draft in
                NavigationStack {
                    RSSTaskEditorView(draft: draft) { reload.fire() }
                }
            }
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func taskRow(_ task: JSONValue, reload: Reload) -> some View {
        let id = task.first(of: "id", "task_id").displayString ?? ""
        let enabled = task.first(of: "enabled").bool ?? true
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(task.first(of: "name").displayString ?? "—")
                    .font(.subheadline.weight(.medium))
                Spacer()
                StatusBadge(enabled ? "已启用" : "已停用", tone: enabled ? .good : .neutral)
            }
            if let url = task.first(of: "rss_url").displayString {
                Text(url).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            HStack(spacing: 8) {
                Text(Fmt.cron(task.first(of: "cron").string))
                if let last = task.first(of: "last_sync_at").displayString {
                    Text("· " + Fmt.relative(.string(last)))
                }
                if let matched = task.first(of: "last_tmdb_matched_count").int {
                    Text("· 匹配 \(matched)")
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            HStack(spacing: 16) {
                Button("立即运行") {
                    runner.run("已触发", operation: {
                        let api = try session.requireAPI()
                        return try await api.rss.runRssNow(.object(["id": .string(id)]))
                    }, onSuccess: { await reload() })
                }
                Button(enabled ? "停用" : "启用") {
                    runner.run(enabled ? "已停用" : "已启用", operation: {
                        let api = try session.requireAPI()
                        return try await api.rss.toggleRssTaskEndpoint(
                            ToggleTaskRequest(idValue: id, enabled: !enabled))
                    }, onSuccess: { await reload() })
                }
                Button("编辑") { editing = RSSTaskDraft(task) }
                Button("删除") {
                    runner.run("已删除", operation: {
                        let api = try session.requireAPI()
                        return try await api.rss.deleteRssTask(.object(["id": .string(id)]))
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

/// RSS 任务编辑草稿。
struct RSSTaskDraft: Identifiable {
    var id: String
    var name: String
    var rssURL: String
    var cron: String
    var contentType: String
    var serverIdx: Int
    var syncMissingToMP: Bool
    var enabled: Bool

    init() {
        id = ""
        name = ""
        rssURL = ""
        cron = "0 */6 * * *"
        contentType = "movies"
        serverIdx = 0
        syncMissingToMP = false
        enabled = true
    }

    init(_ task: JSONValue) {
        id = task.first(of: "id", "task_id").displayString ?? ""
        name = task.first(of: "name").string ?? ""
        rssURL = task.first(of: "rss_url").string ?? ""
        cron = task.first(of: "cron").string ?? "0 */6 * * *"
        contentType = task.first(of: "content_type").string ?? "movies"
        serverIdx = task.first(of: "target_server_idx").int ?? 0
        syncMissingToMP = task.first(of: "sync_library_missing_to_mp").bool ?? false
        enabled = task.first(of: "enabled").bool ?? true
    }
}

struct RSSTaskEditorView: View {
    @State var draft: RSSTaskDraft
    let onSaved: () -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var runner = ActionRunner()

    private var isNew: Bool { draft.id.isEmpty }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("任务名称", text: $draft.name)
                TextField("RSS 地址", text: $draft.rssURL, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Cron 表达式", text: $draft.cron)
                    .textInputAutocapitalization(.never)
                Text(Fmt.cron(draft.cron)).font(.caption).foregroundStyle(.secondary)
            }
            Section("内容") {
                Picker("内容类型", selection: $draft.contentType) {
                    Text("电影").tag("movies")
                    Text("剧集").tag("tv")
                }
                Stepper("目标服务器序号 \(draft.serverIdx)", value: $draft.serverIdx, in: 0...9)
                Toggle("缺集同步到 MoviePilot", isOn: $draft.syncMissingToMP)
                Toggle("启用", isOn: $draft.enabled)
            }
            Section {
                Button(isNew ? "创建任务" : "保存修改") { save() }
                    .disabled(draft.name.isEmpty || draft.rssURL.isEmpty)
            }
        }
        .navigationTitle(isNew ? "新增 RSS 任务" : "编辑 RSS 任务")
        .actionFeedback(runner)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }
        }
    }

    private func save() {
        runner.run("已保存", operation: {
            let api = try session.requireAPI()
            if isNew {
                return try await api.rss.createRssTask(
                    RssTaskModel(name: draft.name, rssUrl: draft.rssURL, cron: draft.cron,
                                 targetServerIdx: draft.serverIdx, contentType: draft.contentType,
                                 syncLibraryMissingToMp: draft.syncMissingToMP, enabled: draft.enabled))
            }
            return try await api.rss.updateRssTask(
                UpdateRssTaskRequest(idValue: draft.id, name: draft.name, rssUrl: draft.rssURL,
                                     cron: draft.cron, targetServerIdx: draft.serverIdx,
                                     contentType: draft.contentType,
                                     syncLibraryMissingToMp: draft.syncMissingToMP,
                                     enabled: draft.enabled))
        }, onSuccess: {
            onSaved()
            dismiss()
        })
    }
}
