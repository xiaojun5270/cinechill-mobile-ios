import Foundation
import SwiftUI

/// 任务中心：运行进度 + 已保存的海报/主题任务。
struct TaskCenterView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    var body: some View {
        RemoteList(title: "自动封面", refreshOnAppear: true) {
            let api = try session.requireAPI()
            async let progressRequest = Probe.json { try await api.tasks.getProgress() }
            async let savedRequest = Probe.json { try await api.tasks.getTasks() }
            async let templatesRequest = Probe.json { try await api.resources.getTemplatesV2() }
            let (progress, saved, templates) = await (progressRequest, savedRequest, templatesRequest)
            return JSONValue.object(["progress": progress, "saved": saved, "templates": templates])
        } content: { value, reload in
            progressSection(value["progress"], reload: reload)
            savedSection(value["saved"], templates: CoverData.templates(from: value["templates"]),
                         reload: reload)
            Section {
                NavigationLink {
                    TaskEditorView(existing: .null, reload: reload)
                } label: {
                    Label("新建计划任务", systemImage: "plus.circle")
                }
            }
        }
        .actionFeedback(runner)
    }

    // MARK: - 进度

    @ViewBuilder
    private func progressSection(_ progress: JSONValue, reload: Reload) -> some View {
        let tasks = normalizedProgressTasks(progress)
        let running = tasks.filter { isActiveProgressTask($0) }
        let finished = tasks.filter { !isActiveProgressTask($0) }
        Section("运行中（\(running.count)）") {
            if running.isEmpty {
                if let text = progress.deepFirst(of: "message", "status").displayString {
                    Text(text).font(.footnote).foregroundStyle(.secondary)
                } else {
                    EmptyRow("当前没有运行中的任务")
                }
            }
            ForEach(Array(running.enumerated()), id: \.offset) { _, task in
                progressTaskRow(task, active: true, reload: reload)
            }
        }
        Section("最近完成（\(finished.count)）") {
            if finished.isEmpty { EmptyRow("暂无已完成任务") }
            ForEach(Array(finished.enumerated()), id: \.offset) { _, task in
                progressTaskRow(task, active: false, reload: reload)
            }
            if !finished.isEmpty {
                Button(role: .destructive) {
                    clearProgress(finished, reload: reload)
                } label: {
                    Label("清除已完成记录", systemImage: "eraser")
                }
            }
        }
    }

    @ViewBuilder
    private func progressTaskRow(_ task: JSONValue, active: Bool, reload: Reload) -> some View {
        let runID = task.first(of: "run_id", "id", "task_id").displayString ?? ""
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(task.first(of: "name", "task_name", "title").displayString ?? "任务")
                    .font(.subheadline.weight(.medium))
                Spacer()
                if let state = task.first(of: "status", "state").displayString {
                    StatusBadge(state, tone: badgeTone(for: state))
                }
            }
            let ratio = Fmt.ratio(task.deepFirst(of: "progress", "percent", "ratio"))
            ProgressView(value: ratio)
            HStack {
                if let step = task.deepFirst(of: "message", "current", "step", "display_status").displayString {
                    Text(step).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                }
                Spacer()
                Text(Fmt.percent(.double(ratio), digits: 0))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if !runID.isEmpty {
                Button(active ? "停止" : "清除记录") {
                    if active {
                        runner.run("已请求停止", operation: {
                            let api = try session.requireAPI()
                            return try await api.tasks.stopTask(.object(["run_id": .string(runID)]))
                        }, onSuccess: { await reload() })
                    } else {
                        runner.run("已清除进度记录", operation: {
                            let api = try session.requireAPI()
                            return try await api.tasks.clearTaskProgress(.object(["run_id": .string(runID)]))
                        }, onSuccess: { await reload() })
                    }
                }
                .font(.caption)
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
        }
    }

    private func clearProgress(_ tasks: [JSONValue], reload: Reload) {
        let runIDs = tasks.compactMap { $0.first(of: "run_id", "id", "task_id").displayString }
        runner.run("已清除完成记录", operation: {
            let api = try session.requireAPI()
            var cleared = 0
            for runID in runIDs {
                _ = try await api.tasks.clearTaskProgress(.object(["run_id": .string(runID)]))
                cleared += 1
            }
            return .object(["success": .bool(true), "cleared": .int(cleared)])
        }, onSuccess: { await reload() })
    }

    /// v73 以 run_id 为键返回任务对象，旧版本也可能直接返回数组。
    private func normalizedProgressTasks(_ value: JSONValue) -> [JSONValue] {
        let list = value.list("running", "tasks", "items")
            .filter { $0.object != nil }
        if !list.isEmpty { return list }

        let keyedTasks = value["tasks"].object ?? value.object ?? [:]
        let wrapperKeys: Set<String> = [
            "message", "status", "success", "ok", "detail", "error", "msg",
        ]
        return keyedTasks.keys.sorted(by: >).compactMap { runID in
            guard !wrapperKeys.contains(runID), var task = keyedTasks[runID]?.object else { return nil }
            if task["run_id"]?.isNull != false {
                task["run_id"] = .string(runID)
            }
            return .object(task)
        }
    }

    private func isActiveProgressTask(_ task: JSONValue) -> Bool {
        if task.first(of: "cancel_requested", "cancellation_requested").bool == true { return true }
        let state = task.first(of: "status", "state").displayString?.lowercased() ?? ""
        return ["running", "pending", "queued", "waiting", "stopping", "cancelling"].contains(state)
    }

    // MARK: - 已保存任务

    @ViewBuilder
    private func savedSection(_ saved: JSONValue, templates: [JSONValue], reload: Reload) -> some View {
        let tasks = saved.list("tasks", "items")
        Section("计划任务") {
            if tasks.isEmpty { EmptyRow("没有已保存的任务") }
            ForEach(Array(tasks.enumerated()), id: \.offset) { _, task in
                let id = task.first(of: "id", "task_id").displayString ?? ""
                let enabled = task.first(of: "enabled", "is_enabled").bool ?? true
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(task.first(of: "name", "title").displayString ?? "—")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        StatusBadge(enabled ? "已启用" : "已停用", tone: enabled ? .good : .neutral)
                    }
                    Text(Fmt.cron(task.first(of: "cron", "schedule").string))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let preset = task.first(of: "preset_filename", "preset").displayString {
                        if let template = templates.first(where: { CoverData.filename(of: $0) == preset }) {
                            HStack(spacing: 10) {
                                CoverArtworkView(value: template, contentMode: .fill,
                                                 placeholderIcon: "photo.artframe")
                                    .frame(width: 92, height: 54)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(TemplatesView.name(of: template).isEmpty
                                         ? preset : TemplatesView.name(of: template))
                                        .font(.caption.weight(.medium)).lineLimit(1)
                                    Text(preset).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                                }
                            }
                        } else {
                            Text(preset).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                        }
                    }
                    HStack(spacing: 14) {
                        NavigationLink("编辑") {
                            TaskEditorView(existing: task, reload: reload)
                        }
                        Button("立即运行") {
                            runner.run("已触发", operation: {
                                let api = try session.requireAPI()
                                return try await api.tasks.runSavedTaskEndpoint(RunSavedTaskRequest(idValue: id))
                            }, onSuccess: { await reload() })
                        }
                        Button(enabled ? "停用" : "启用") {
                            runner.run(enabled ? "已停用" : "已启用", operation: {
                                let api = try session.requireAPI()
                                return try await api.tasks.toggleTaskEndpoint(
                                    ToggleTaskRequest(idValue: id, enabled: !enabled))
                            }, onSuccess: { await reload() })
                        }
                        Button("删除") {
                            runner.run("已删除", operation: {
                                let api = try session.requireAPI()
                                return try await api.tasks.deleteTaskEndpoint(.object(["id": .string(id)]))
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
    }
}

/// 计划任务编辑器：新建走 `/api/create_task`，修改走 `/api/update_task`，
/// 「立即执行」走 `/api/run_task`（不落库，仅按当前选择跑一次）。
struct TaskEditorView: View {
    let existing: JSONValue
    let reload: Reload

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var runner = ActionRunner()

    @State private var name: String
    @State private var cron: String
    @State private var preset: String
    @State private var mode: String
    @State private var enabled: Bool
    @State private var autoInclude: Bool
    @State private var selected: Set<String>
    @State private var libraries: [JSONValue] = []
    @State private var presets: [JSONValue] = []
    @State private var manualLibraryID = ""
    @State private var manualLibraryName = ""
    @State private var connection: ConnectionRequest?
    @State private var optionsLoaded = false

    init(existing: JSONValue, reload: Reload) {
        self.existing = existing
        self.reload = reload
        _name = State(initialValue: existing.first(of: "name", "title").displayString ?? "")
        _cron = State(initialValue: existing.first(of: "cron", "schedule").displayString ?? "0 4 * * *")
        _preset = State(initialValue: existing.first(of: "preset_filename", "preset").displayString ?? "")
        let savedMode = existing.first(of: "mode").displayString ?? "random"
        _mode = State(initialValue: savedMode == "latest" || savedMode == "sequential" ? "latest" : "random")
        _enabled = State(initialValue: existing.first(of: "enabled", "is_enabled").bool ?? true)
        _autoInclude = State(initialValue: existing.first(of: "auto_include_new_libraries").bool ?? false)
        let ids = existing.list("targets", "libraries").compactMap {
            $0.first(of: "library_id", "libraryId", "id").displayString
        }
        _selected = State(initialValue: Set(ids))
    }

    private var taskID: String {
        existing.first(of: "id", "task_id").displayString ?? ""
    }

    var body: some View {
        Form {
            basicSection
            presetSection
            targetSection
            actionSection
        }
        .navigationTitle(taskID.isEmpty ? "新建任务" : "编辑任务")
        .actionFeedback(runner)
        .task {
            guard !optionsLoaded else { return }
            optionsLoaded = true
            await loadOptions()
        }
    }

    @ViewBuilder
    private var basicSection: some View {
        Section("基本信息") {
            TextField("任务名称", text: $name)
            TextField("Cron 表达式", text: $cron)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Text(Fmt.cron(cron)).font(.caption).foregroundStyle(.secondary)
            Picker("取图方式", selection: $mode) {
                Text("随机").tag("random")
                Text("最新入库").tag("latest")
            }
            .pickerStyle(.segmented)
            Toggle("启用", isOn: $enabled)
            Toggle("自动包含新媒体库", isOn: $autoInclude)
        }
    }

    @ViewBuilder
    private var presetSection: some View {
        Section("封面模板") {
            ForEach(Array(presets.enumerated()), id: \.offset) { _, template in
                let filename = CoverData.filename(of: template)
                Button {
                    preset = filename
                } label: {
                    HStack(spacing: 12) {
                        CoverArtworkView(value: template, contentMode: .fill,
                                         placeholderIcon: "photo.artframe")
                            .frame(width: 104, height: 62)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(TemplatesView.name(of: template).isEmpty
                                 ? filename : TemplatesView.name(of: template))
                                .foregroundStyle(.primary)
                            Text(filename).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer()
                        if preset == filename {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .disabled(filename.isEmpty)
            }
            TextField("模板文件名", text: $preset)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    @ViewBuilder
    private var targetSection: some View {
        Section("目标媒体库") {
            if libraries.isEmpty {
                Text("未能自动读取媒体库，可在下方手动填写 ID。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(libraries.enumerated()), id: \.offset) { _, library in
                let id = libraryID(library)
                Button {
                    if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
                } label: {
                    HStack(spacing: 12) {
                        CoverArtworkView(value: library, contentMode: .fill,
                                         placeholderIcon: "rectangle.stack")
                            .frame(width: 84, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(libraryName(library)).foregroundStyle(.primary)
                            Text(id).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selected.contains(id) {
                            Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .disabled(id.isEmpty)
            }
            TextField("手动添加：媒体库 ID", text: $manualLibraryID)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("手动添加：媒体库名称（可选）", text: $manualLibraryName)
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        Section {
            Button {
                save()
            } label: {
                Label(taskID.isEmpty ? "创建任务" : "保存修改", systemImage: "square.and.arrow.down")
            }
            .disabled(runner.isRunning || !canSubmit)

            Button {
                runBatch()
            } label: {
                Label("立即执行一次（不保存）", systemImage: "play.circle")
            }
            .disabled(runner.isRunning || preset.isEmpty || targets().isEmpty)

        } footer: {
            Text("已选择 \(targets().count) 个媒体库。保存格式与 Web 端任务配置一致。")
        }
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !cron.trimmingCharacters(in: .whitespaces).isEmpty
            && !preset.isEmpty
            && !targets().isEmpty
    }

    private func libraryID(_ library: JSONValue) -> String {
        library.first(of: "library_id", "libraryId", "id", "Id", "ItemId").displayString ?? ""
    }

    private func libraryName(_ library: JSONValue) -> String {
        library.first(of: "library_name", "name", "Name", "title").displayString ?? "未命名"
    }

    /// 媒体库来自 Emby 封面接口，模板来自封面模板接口；任何一步失败都不影响手动填写。
    private func loadOptions() async {
        guard let api = session.api else { return }
        async let templatesRequest = Probe.json { try await api.resources.getTemplatesV2() }
        async let connectionRequest = EmbyConnection.load(api: api)
        let (templates, loadedConnection) = await (templatesRequest, connectionRequest)
        presets = CoverData.templates(from: templates)
        guard let connection = loadedConnection else { return }
        self.connection = connection
        let covers = await Probe.json { try await api.server.getLibraryCovers(connection) }
        var list = covers.list("libraries", "items", "data", "views")
        let known = Set(list.map { libraryID($0) })
        for target in existing.list("targets", "libraries") {
            let id = target.first(of: "library_id", "libraryId", "id").displayString ?? ""
            if !id.isEmpty && !known.contains(id) { list.append(target) }
        }
        libraries = list
    }

    private func targets() -> [TaskTarget] {
        var result: [TaskTarget] = []
        var seen: Set<String> = []
        for library in libraries {
            let id = libraryID(library)
            guard !id.isEmpty, selected.contains(id), !seen.contains(id) else { continue }
            seen.insert(id)
            result.append(target(id: id, name: libraryName(library)))
        }
        let manual = manualLibraryID.trimmingCharacters(in: .whitespaces)
        if !manual.isEmpty, !seen.contains(manual) {
            let label = manualLibraryName.trimmingCharacters(in: .whitespaces)
            result.append(target(id: manual, name: label.isEmpty ? manual : label))
        }
        return result
    }

    private func target(id: String, name: String) -> TaskTarget {
        TaskTarget(serverIdx: 0,
                   libraryId: id,
                   libraryName: name)
    }

    private func save() {
        let list = targets()
        let payloadName = name.trimmingCharacters(in: .whitespaces)
        let payloadCron = cron.trimmingCharacters(in: .whitespaces)
        let id = taskID
        runner.run("已保存", operation: {
            let api = try session.requireAPI()
            if id.isEmpty {
                return try await api.tasks.createTaskEndpoint(
                    CreateTaskRequest(name: payloadName,
                                      cron: payloadCron,
                                      presetFilename: preset,
                                      targets: list,
                                      mode: mode,
                                      enabled: enabled,
                                      autoIncludeNewLibraries: autoInclude))
            }
            return try await api.tasks.updateTaskEndpoint(
                UpdateTaskRequest(idValue: id,
                                  name: payloadName,
                                  cron: payloadCron,
                                  presetFilename: preset,
                                  targets: list,
                                  mode: mode,
                                  enabled: enabled,
                                  autoIncludeNewLibraries: autoInclude))
        }, onSuccess: {
            await reload()
            dismiss()
        })
    }

    private func runBatch() {
        let list = targets()
        runner.run("已提交执行", operation: {
            let api = try session.requireAPI()
            return try await api.tasks.runTaskBatch(
                RunTaskRequest(presetFilename: preset, targets: list, mode: mode))
        }, onSuccess: { await reload() })
    }
}

/// 系统日志：按级别/关键词过滤。
struct SystemLogsView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var level = "ALL"
    @State private var keyword = ""
    @State private var hideDebug = false
    @State private var queryKey = 0

    private let levels = ["ALL", "ERROR", "WARNING", "INFO", "DEBUG"]

    var body: some View {
        RemoteList(title: "系统日志", cacheKey: "system-logs-\(queryKey)", refreshOnAppear: true) {
            let api = try session.requireAPI()
            return try await api.tasks.getSystemLogs(
                level: level,
                keyword: keyword.isEmpty ? nil : keyword,
                category: "ALL",
                limit: 1000,
                hideDebug: hideDebug)
        } content: { value, reload in
            Section("过滤") {
                Picker("级别", selection: $level) {
                    ForEach(levels, id: \.self) { Text($0 == "ALL" ? "全部" : $0).tag($0) }
                }
                .onChange(of: level) { _, newValue in
                    if newValue == "DEBUG" { hideDebug = false }
                    queryKey += 1
                }
                Toggle("隐藏 DEBUG", isOn: $hideDebug)
                    .disabled(level == "DEBUG")
                    .onChange(of: hideDebug) { _, _ in queryKey += 1 }
            }
            let logs = SystemLogPayload.entries(from: value)
            Section("日志（\(logs.count)）") {
                if logs.isEmpty { EmptyRow("服务端没有返回符合条件的日志") }
                ForEach(Array(logs.enumerated()), id: \.offset) { _, log in
                    logRow(log)
                }
            }
            Section {
                NavigationLink {
                    SystemLogsLiveView(level: level, keyword: keyword, hideDebug: hideDebug)
                } label: {
                    Label("实时日志", systemImage: "dot.radiowaves.left.and.right")
                }
                Button(role: .destructive) {
                    runner.run("已清空日志", operation: {
                        let api = try session.requireAPI()
                        return try await api.tasks.clearSystemLogs()
                    }, onSuccess: { await reload() })
                } label: {
                    Label("清空日志", systemImage: "trash")
                }
            } footer: {
                Text("实时日志走服务端的 SSE 推送，进入页面后自动连接，离开即断开。")
            }
        }
        .id(queryKey)
        .searchable(text: $keyword, prompt: "日志关键词")
        .onSubmit(of: .search) { queryKey += 1 }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func logRow(_ log: JSONValue) -> some View {
        if let text = log.string {
            Text(text).font(.system(.caption, design: .monospaced))
        } else {
            let lv = log.first(of: "level", "levelname").displayString ?? "INFO"
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    StatusBadge(lv, tone: logTone(lv))
                    if let time = log.first(of: "time", "timestamp", "created_at").displayString {
                        Text(Fmt.dateTime(.string(time)))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    if let category = log.first(of: "category", "module", "logger").displayString {
                        Text(category).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                    }
                }
                Text(log.first(of: "message", "msg", "text").displayString ?? "—")
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
    }

    private func logTone(_ level: String) -> BadgeTone {
        switch level.uppercased() {
        case "ERROR", "CRITICAL": return .bad
        case "WARNING", "WARN": return .warning
        case "DEBUG": return .neutral
        default: return .info
        }
    }
}

/// 系统日志实时流：`GET /api/system_logs/stream`（SSE）。
/// 进入页面自动连接，退出时 `.task` 取消随即断开。
struct SystemLogsLiveView: View {
    let level: String
    let keyword: String
    let hideDebug: Bool

    @EnvironmentObject private var session: AppSession
    @State private var lines: [LiveLine] = []
    @State private var isConnected = false
    @State private var errorText: String?
    @State private var autoScroll = true
    @State private var attempt = 0

    /// SSE 推来的一行日志。服务端可能推对象，也可能推纯文本。
    struct LiveLine: Identifiable {
        let id = UUID()
        var level: String
        var time: String?
        var message: String
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section("连接") {
                    HStack {
                        StatusBadge(isConnected ? "已连接" : "已断开", tone: isConnected ? .good : .neutral)
                        Spacer()
                        Text("\(lines.count) 行").font(.caption).foregroundStyle(.secondary)
                    }
                    Toggle("自动滚动到最新", isOn: $autoScroll)
                    if let errorText {
                        FailureRow(message: errorText) { attempt += 1 }
                    }
                }
                Section("日志") {
                    if lines.isEmpty { EmptyRow(isConnected ? "等待新日志…" : "暂无日志") }
                    ForEach(lines) { line in
                        row(line).id(line.id)
                    }
                }
                Section {
                    Button("清空当前视图") { lines.removeAll() }
                        .disabled(lines.isEmpty)
                } footer: {
                    Text("这里只清空手机上已收到的内容，不会删除服务端日志。过滤条件沿用上一页的设置。")
                }
            }
            .onChange(of: lines.count) { _, _ in
                guard autoScroll, let last = lines.last else { return }
                withAnimation(.easeOut(duration: 0.15)) { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
        .navigationTitle("实时日志")
        .task(id: attempt) { await listen() }
    }

    @ViewBuilder
    private func row(_ line: LiveLine) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                StatusBadge(line.level, tone: tone(line.level))
                if let time = line.time {
                    Text(time).font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                }
            }
            Text(line.message)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    private func tone(_ level: String) -> BadgeTone {
        switch level.uppercased() {
        case "ERROR", "CRITICAL": return .bad
        case "WARNING", "WARN": return .warning
        case "DEBUG": return .neutral
        default: return .info
        }
    }

    private func listen() async {
        errorText = nil
        do {
            let api = try session.requireAPI()
            let latestID = await loadSnapshot(api: api)
            let request = try api.tasks.streamSystemLogsRequest(
                level: level,
                keyword: keyword.isEmpty ? nil : keyword,
                category: "ALL",
                lastEventId: latestID,
                hideDebug: hideDebug)
            isConnected = true
            for try await event in EventStream.events(client: api.client, request: request) {
                if let name = event.event, name == "ping" || name == "heartbeat" { continue }
                if event.event == "reset" {
                    _ = await loadSnapshot(api: api)
                    continue
                }
                append(event.json)
            }
            isConnected = false
        } catch let error as APIError {
            isConnected = false
            if error.isAuthFailure { session.handle(error: error) }
            if case .cancelled = error {} else { errorText = error.errorDescription }
        } catch {
            isConnected = false
            errorText = error.localizedDescription
        }
    }

    /// 一条事件可能是单条日志、也可能是一批日志。
    private func append(_ value: JSONValue) {
        for payload in SystemLogPayload.entries(from: value) {
            guard let line = makeLine(payload) else { continue }
            lines.append(line)
        }
        if lines.count > 1000 { lines.removeFirst(lines.count - 1000) }
    }

    /// 先取一次完整快照，再从 latest_id 后继续接收 SSE，避免进入实时页时只看到新日志。
    private func loadSnapshot(api: CineChillAPI) async -> Int? {
        do {
            let value = try await api.tasks.getSystemLogs(
                level: level,
                keyword: keyword.isEmpty ? nil : keyword,
                category: "ALL",
                limit: 1000,
                hideDebug: hideDebug)
            lines = SystemLogPayload.entries(from: value).compactMap { makeLine($0) }
            return value.first(of: "latest_id", "latestId", "last_event_id").int
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            errorText = error.errorDescription ?? "系统日志读取失败"
        } catch {
            errorText = error.localizedDescription
        }
        return nil
    }

    private func makeLine(_ payload: JSONValue) -> LiveLine? {
        if payload.isNull { return nil }
        if let text = payload.string {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return LiveLine(level: guessLevel(trimmed), time: nil, message: trimmed)
        }
        guard let message = payload.first(of: "message", "msg", "text", "line").displayString else { return nil }
        let raw = payload.first(of: "time", "timestamp", "created_at").displayString
        return LiveLine(level: payload.first(of: "level", "levelname").displayString ?? guessLevel(message),
                        time: raw.map { Fmt.dateTime(.string($0)) },
                        message: message)
    }

    private func guessLevel(_ text: String) -> String {
        let upper = text.uppercased()
        for candidate in ["CRITICAL", "ERROR", "WARNING", "DEBUG"] where upper.contains(candidate) {
            return candidate
        }
        return "INFO"
    }
}

/// v73 的日志快照和 SSE 都以文本块返回；旧服务端也可能返回结构化数组。
private enum SystemLogPayload {
    static func entries(from value: JSONValue) -> [JSONValue] {
        if let items = value.array { return items }

        for key in ["logs", "lines", "items", "events"] {
            if let items = value[key].array { return items }
        }

        if let raw = textBlock(in: value) {
            return raw.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { .string($0) }
        }
        if value.first(of: "message", "msg", "line").displayString != nil {
            return [value]
        }
        return []
    }

    private static func textBlock(in value: JSONValue) -> String? {
        if let text = value.string { return text }
        for key in ["logs", "chunk", "content", "text", "data", "raw"] {
            if let text = value[key].string { return text }
        }
        return nil
    }
}
