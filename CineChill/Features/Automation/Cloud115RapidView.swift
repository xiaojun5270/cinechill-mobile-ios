import SwiftUI

/// 115 云端秒传 / 转存：在两个 115 账号之间直接转存文件，不消耗上传带宽。
/// 源文件条目直接沿用「浏览云端目录」返回的原始 JSON，避免猜测服务端字段名。
struct Cloud115RapidView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    @AppStorage("cloud115.rapid.lastTargetCID") private var lastTargetCID = ""
    @State private var sourceCookie = ""
    @State private var targetCookie = ""
    @State private var sameAccount = true
    @State private var items: [Cloud115ItemDraft] = []
    @State private var target = Cloud115Target()
    @State private var concurrency = 4
    @State private var jobIDInput = ""
    @State private var pickingFiles = false
    @State private var pickingFolder = false
    @State private var prepared = false

    private var effectiveTargetCookie: String { sameAccount ? sourceCookie : targetCookie }
    private var targetCID: String { target.cid.trimmingCharacters(in: .whitespaces) }
    private var trimmedJobID: String { jobIDInput.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSubmit: Bool {
        !sourceCookie.isEmpty && !effectiveTargetCookie.isEmpty && !targetCID.isEmpty && !items.isEmpty
    }

    var body: some View {
        Form {
            credentialSection
            sourceSection
            targetSection
            Section("并发") {
                Stepper("秒传并发 \(concurrency)", value: $concurrency, in: 1...16)
            }
            submitSection
            recentJobSection
            lookupSection
        }
        .navigationTitle("云端秒传")
        .actionFeedback(runner)
        .sheet(isPresented: $pickingFiles) {
            NavigationStack {
                Cloud115FilePickerView(cookie: sourceCookie) { picked in
                    items.append(contentsOf: picked.map { Cloud115ItemDraft(raw: $0) })
                }
            }
        }
        .sheet(isPresented: $pickingFolder) {
            NavigationStack {
                Cloud115FolderPickerView(cookie: effectiveTargetCookie) { picked in
                    target = picked
                }
            }
        }
        .task {
            guard !prepared else { return }
            prepared = true
            if target.cid.isEmpty { target.cid = lastTargetCID }
        }
    }
    @ViewBuilder
    private var credentialSection: some View {
        Section {
            SecureField("源账号 115 Cookie", text: $sourceCookie)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Toggle("目标使用同一账号", isOn: $sameAccount)
            if !sameAccount {
                SecureField("目标账号 115 Cookie", text: $targetCookie)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        } header: {
            Text("账号 Cookie")
        } footer: {
            Text("Cookie 仅提交给你自己的 CineChill 服务器，本机不做保存；提交成功后输入框会自动清空。")
        }
    }

    @ViewBuilder
    private var sourceSection: some View {
        Section {
            if items.isEmpty {
                Text("尚未选择文件").font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name).font(.subheadline).lineLimit(1)
                    HStack(spacing: 8) {
                        Text(item.sizeText)
                        if let sha1 = item.sha1 { Text("SHA1 " + String(sha1.prefix(12))) }
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
            }
            .onDelete { items.remove(atOffsets: $0) }
            Button {
                pickingFiles = true
            } label: {
                Label("浏览源账号目录", systemImage: "folder.badge.plus")
            }
            .disabled(sourceCookie.isEmpty)
        } header: {
            Text("源文件（\(items.count)）")
        } footer: {
            Text("左滑可移除条目。每个条目按服务端返回的原始字段整体回传，秒传所需的 sha1 / pick_code 会一并提交。")
        }
    }
    @ViewBuilder
    private var targetSection: some View {
        Section("目标目录") {
            TextField("目标 CID", text: $target.cid)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("目录名称（仅备注）", text: $target.name)
            if !target.path.isEmpty {
                Text(target.path).font(.caption2).foregroundStyle(.tertiary)
            }
            Button {
                pickingFolder = true
            } label: {
                Label("从目标账号选择目录", systemImage: "externaldrive.badge.plus")
            }
            .disabled(effectiveTargetCookie.isEmpty)
        }
    }

    @ViewBuilder
    private var submitSection: some View {
        Section {
            Button {
                submit()
            } label: {
                Label("提交秒传任务", systemImage: "bolt.horizontal.circle")
            }
            .disabled(!canSubmit)
        } footer: {
            Text("秒传只在目标账号建立文件引用；若 115 没有对应的秒传资源，任务会以失败结束。")
        }
    }

    @ViewBuilder
    private var recentJobSection: some View {
        let jobID = runner.lastResult.deepFirst(of: "job_id", "jobId", "task_id", "id").displayString ?? ""
        if !jobID.isEmpty {
            Section("最近提交") {
                KeyValueRow("任务 ID", jobID, monospaced: true)
                NavigationLink {
                    CloudRapidJobView(jobID: jobID)
                } label: {
                    Label("查看秒传进度", systemImage: "chart.bar.doc.horizontal")
                }
            }
        }
    }
    @ViewBuilder
    private var lookupSection: some View {
        Section("查询已有任务") {
            TextField("秒传任务 ID", text: $jobIDInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            NavigationLink {
                CloudRapidJobView(jobID: trimmedJobID)
            } label: {
                Label("查看任务状态", systemImage: "doc.text.magnifyingglass")
            }
            .disabled(trimmedJobID.isEmpty)
        }
    }

    private func submit() {
        let payload = CloudRapidPayload(sourceCookie: sourceCookie,
                                        targetCookie: effectiveTargetCookie,
                                        targetCid: targetCID,
                                        targetPath: target.path,
                                        concurrency: concurrency,
                                        items: items.map(\.raw))
        runner.run("已提交秒传", operation: {
            let api = try session.requireAPI()
            return try await api.upload115.rapidTransferCloud115(payload)
        }, onSuccess: {
            lastTargetCID = targetCID
            sourceCookie = ""
            targetCookie = ""
        })
    }
}

/// 秒传目标目录（CID + 展示路径）。
struct Cloud115Target: Hashable {
    var cid: String = ""
    var name: String = ""
    var path: String = ""
}

/// 待秒传的源文件条目，保留浏览接口返回的原始 JSON。
struct Cloud115ItemDraft: Identifiable, Hashable {
    var id = UUID()
    var raw: JSONValue

    var name: String { Cloud115Entry.name(raw) }
    var sizeText: String { Fmt.bytes(raw.first(of: "size", "file_size", "s")) }
    var sha1: String? { raw.first(of: "sha1", "sha").displayString }
}

struct Cloud115Crumb: Hashable {
    var cid: String
    var name: String
}

/// 云端浏览响应的字段兜底解析（该接口 200 响应未声明 schema）。
enum Cloud115Entry {
    /// 兼容 `{folders:[], files:[]}` 与单一列表两种返回形态。
    static func entries(in value: JSONValue) -> [JSONValue] {
        let folders = value["folders"].array ?? value["dirs"].array ?? []
        let files = value["files"].array ?? []
        if !folders.isEmpty || !files.isEmpty { return folders + files }
        return value.list("items", "data", "list")
    }

    static func isFolder(_ entry: JSONValue) -> Bool {
        if let flag = entry.first(of: "is_dir", "isDir", "is_folder").bool { return flag }
        if let type = entry.first(of: "type", "kind").string {
            if type == "folder" || type == "dir" { return true }
            if type == "file" { return false }
        }
        // 115 的文件条目带 sha1 / pick_code，目录条目只有 cid。
        if !entry.first(of: "sha1", "sha", "pick_code", "pc").isNull { return false }
        return !entry.first(of: "cid", "category_id").isNull
    }

    static func cid(_ entry: JSONValue) -> String {
        entry.first(of: "cid", "id", "file_id", "fid").displayString ?? ""
    }

    static func name(_ entry: JSONValue) -> String {
        entry.first(of: "name", "file_name", "n").displayString ?? "—"
    }
}

/// 浏览源账号的 115 云端目录并多选文件；点按目录进入下一层。
struct Cloud115FilePickerView: View {
    let cookie: String
    let onPick: ([JSONValue]) -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var stack: [Cloud115Crumb] = [Cloud115Crumb(cid: "0", name: "根目录")]
    @State private var entries: [JSONValue] = []
    @State private var selected: [JSONValue] = []
    @State private var loading = false
    @State private var failure: String?

    private var current: Cloud115Crumb { stack.last ?? Cloud115Crumb(cid: "0", name: "根目录") }
    private var currentPath: String { "/" + stack.dropFirst().map(\.name).joined(separator: "/") }
    private var folders: [JSONValue] { entries.filter { Cloud115Entry.isFolder($0) } }
    private var files: [JSONValue] { entries.filter { !Cloud115Entry.isFolder($0) } }

    var body: some View {
        List {
            Section {
                HStack {
                    Text(currentPath).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    Spacer()
                    if stack.count > 1 {
                        Button("上一级") { stack.removeLast() }
                            .font(.caption)
                            .buttonStyle(.borderless)
                    }
                }
                KeyValueRow("已选文件", String(selected.count))
            }
            if loading {
                LoadingRow()
            } else if let failure {
                Section {
                    Text(failure).font(.footnote).foregroundStyle(.red)
                    Button("重试") { Task { await load() } }
                }
            } else {
                listSections
            }
        }
        .navigationTitle("选择源文件")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成（\(selected.count)）") {
                    onPick(selected)
                    dismiss()
                }
                .disabled(selected.isEmpty)
            }
        }
        .task(id: current.cid) { await load() }
    }

    @ViewBuilder
    private var listSections: some View {
        Section("目录（\(folders.count)）") {
            if folders.isEmpty { EmptyRow("没有子目录") }
            ForEach(Array(folders.enumerated()), id: \.offset) { _, entry in
                folderRow(entry)
            }
        }
        Section("文件（\(files.count)）") {
            if files.isEmpty { EmptyRow("没有文件") }
            ForEach(Array(files.enumerated()), id: \.offset) { _, entry in
                fileRow(entry)
            }
        }
    }

    @ViewBuilder
    private func folderRow(_ entry: JSONValue) -> some View {
        let cid = Cloud115Entry.cid(entry)
        let name = Cloud115Entry.name(entry)
        HStack {
            Image(systemName: "folder").foregroundStyle(.tint)
            Text(name).font(.subheadline).lineLimit(1)
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !cid.isEmpty else { return }
            stack.append(Cloud115Crumb(cid: cid, name: name))
        }
    }

    @ViewBuilder
    private func fileRow(_ entry: JSONValue) -> some View {
        let picked = selected.contains(entry)
        HStack {
            Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(picked ? Color.accentColor : Color.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(Cloud115Entry.name(entry)).font(.subheadline).lineLimit(1)
                Text(Fmt.bytes(entry.first(of: "size", "file_size", "s")))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let index = selected.firstIndex(of: entry) {
                selected.remove(at: index)
            } else {
                selected.append(entry)
            }
        }
    }

    private func load() async {
        guard let api = session.api else {
            failure = "请先登录服务器"
            return
        }
        loading = true
        failure = nil
        do {
            let value = try await api.upload115.browseCloud115(
                CloudBrowsePayload(cookie: cookie, cid: current.cid, includeFiles: true))
            entries = Cloud115Entry.entries(in: value)
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

/// 浏览目标账号的 115 云端目录并选定一个目录作为转存目标。
struct Cloud115FolderPickerView: View {
    let cookie: String
    let onPick: (Cloud115Target) -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var stack: [Cloud115Crumb] = [Cloud115Crumb(cid: "0", name: "根目录")]
    @State private var folders: [JSONValue] = []
    @State private var loading = false
    @State private var failure: String?

    private var current: Cloud115Crumb { stack.last ?? Cloud115Crumb(cid: "0", name: "根目录") }
    private var currentPath: String { "/" + stack.dropFirst().map(\.name).joined(separator: "/") }

    var body: some View {
        List {
            Section {
                HStack {
                    Text(currentPath).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    Spacer()
                    if stack.count > 1 {
                        Button("上一级") { stack.removeLast() }
                            .font(.caption)
                            .buttonStyle(.borderless)
                    }
                }
                Button {
                    onPick(Cloud115Target(cid: current.cid, name: current.name, path: currentPath))
                    dismiss()
                } label: {
                    Label("选择当前目录", systemImage: "checkmark.circle")
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
                Section("子目录（\(folders.count)）") {
                    if folders.isEmpty { EmptyRow("没有子目录") }
                    ForEach(Array(folders.enumerated()), id: \.offset) { _, entry in
                        folderRow(entry)
                    }
                }
            }
        }
        .navigationTitle("选择目标目录")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
        }
        .task(id: current.cid) { await load() }
    }

    @ViewBuilder
    private func folderRow(_ entry: JSONValue) -> some View {
        let cid = Cloud115Entry.cid(entry)
        let name = Cloud115Entry.name(entry)
        HStack {
            Image(systemName: "folder").foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline).lineLimit(1)
                if !cid.isEmpty {
                    Text("CID \(cid)").font(.caption2).foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Button {
                onPick(Cloud115Target(cid: cid, name: name,
                                      path: (currentPath == "/" ? "" : currentPath) + "/" + name))
                dismiss()
            } label: {
                Text("选择").font(.caption)
            }
            .buttonStyle(.borderless)
            .disabled(cid.isEmpty)
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !cid.isEmpty else { return }
            stack.append(Cloud115Crumb(cid: cid, name: name))
        }
    }

    private func load() async {
        guard let api = session.api else {
            failure = "请先登录服务器"
            return
        }
        loading = true
        failure = nil
        do {
            let value = try await api.upload115.browseCloud115(
                CloudBrowsePayload(cookie: cookie, cid: current.cid, includeFiles: false))
            folders = Cloud115Entry.entries(in: value).filter { Cloud115Entry.isFolder($0) }
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

/// 云端秒传任务进度：状态、文件明细，并支持取消。
struct CloudRapidJobView: View {
    let jobID: String

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var confirmingCancel = false

    var body: some View {
        RemoteList(title: "秒传任务") {
            let api = try session.requireAPI()
            return try await api.upload115.getCloudRapidJob(jobId: jobID)
        } content: { value, reload in
            overviewSection(value)
            infoSection(value)
            entriesSection(value)
            actionSection(value, reload: reload)
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func overviewSection(_ value: JSONValue) -> some View {
        let state = value.deepFirst(of: "status", "state", "phase").displayString
        let progress = value.deepFirst(of: "progress", "percent", "percentage")
        Section("概览") {
            KeyValueRow("任务 ID", jobID, monospaced: true)
            if let state {
                HStack {
                    Text("状态").foregroundStyle(.secondary)
                    Spacer()
                    StatusBadge(state, tone: badgeTone(for: state))
                }
            }
            KeyValueRow("总数", value.deepFirst(of: "total", "total_count", "count"))
            KeyValueRow("成功", value.deepFirst(of: "success_count", "succeeded", "completed", "done"))
            KeyValueRow("失败", value.deepFirst(of: "failed_count", "failed", "error_count"))
            if progress.double != nil {
                ProgressView(value: Fmt.ratio(progress)) {
                    Text("进度 " + Fmt.percent(progress))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let message = value.deepFirst(of: "message", "error", "detail").displayString {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func infoSection(_ value: JSONValue) -> some View {
        Section("目标与时间") {
            KeyValueRow("目标目录", value.deepFirst(of: "target_path", "target_cid"))
            KeyValueRow("创建时间", Fmt.dateTime(value.deepFirst(of: "created_at", "started_at", "start_time")))
            KeyValueRow("更新时间", Fmt.dateTime(value.deepFirst(of: "updated_at", "finished_at", "end_time")))
        }
    }

    @ViewBuilder
    private func entriesSection(_ value: JSONValue) -> some View {
        let entries = value.list("items", "files", "results", "details")
        Section("文件明细（\(entries.count)）") {
            if entries.isEmpty { EmptyRow("没有明细") }
            ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                entryRow(entry)
            }
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: JSONValue) -> some View {
        let state = entry.first(of: "status", "state", "result").displayString
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(Cloud115Entry.name(entry)).font(.caption).lineLimit(1)
                Spacer()
                if let state { StatusBadge(state, tone: badgeTone(for: state)) }
            }
            if entry.first(of: "size", "file_size").double != nil {
                Text(Fmt.bytes(entry.first(of: "size", "file_size")))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            if let message = entry.first(of: "message", "error").displayString {
                Text(message).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            }
        }
    }

    @ViewBuilder
    private func actionSection(_ value: JSONValue, reload: Reload) -> some View {
        Section {
            Button {
                reload.fire()
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            Button {
                confirmingCancel = true
            } label: {
                Label("取消该任务", systemImage: "xmark.circle")
            }
            .foregroundStyle(.red)
            JSONInspector(value: value)
        } footer: {
            Text("取消只对尚未开始的条目生效，已完成的转存不会回滚。")
        }
        .confirmationDialog("取消这个秒传任务？", isPresented: $confirmingCancel, titleVisibility: .visible) {
            Button("取消任务", role: .destructive) {
                runner.run("已请求取消", operation: {
                    let api = try session.requireAPI()
                    return try await api.upload115.cancelCloudRapidJob(jobId: jobID)
                }, onSuccess: { await reload() })
            }
            Button("返回", role: .cancel) {}
        }
    }
}
