import SwiftUI

/// 115 上传：任务、状态、并发设置。
struct Upload115View: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var creating = false
    @State private var editing: UploadTaskDraft?

    var body: some View {
        RemoteList(title: "115 上传") {
            let api = try session.requireAPI()
            let tasks = await Probe.json { try await api.upload115.getTasks() }
            let status = await Probe.json { try await api.upload115.getStatus() }
            return JSONValue.object(["tasks": tasks, "status": status])
        } content: { value, reload in
            let status = value["status"]
            Section("总览") {
                KeyValueRow("运行中", status.deepFirst(of: "running", "is_running"))
                KeyValueRow("排队", status.deepFirst(of: "pending", "queued", "queue_size"))
                KeyValueRow("已完成", status.deepFirst(of: "completed", "success", "uploaded"))
                KeyValueRow("失败", status.deepFirst(of: "failed", "error_count"))
                NavigationLink {
                    UploadThreadSettingsView()
                } label: {
                    Label("并发设置", systemImage: "speedometer")
                }
                Button {
                    runner.run("已清空", operation: {
                        let api = try session.requireAPI()
                        return try await api.upload115.clearHistoryRecords()
                    }, onSuccess: { await reload() })
                } label: {
                    Label("清空上传历史", systemImage: "trash")
                }
                .foregroundStyle(.red)
            }

            let tasks = value["tasks"].list("tasks", "items")
            Section("任务（\(tasks.count)）") {
                if tasks.isEmpty { EmptyRow("还没有上传任务") }
                ForEach(Array(tasks.enumerated()), id: \.offset) { _, task in
                    taskRow(task, reload: reload)
                }
            }
            Section {
                Button {
                    creating = true
                } label: {
                    Label("新增上传任务", systemImage: "plus.circle")
                }
                NavigationLink {
                    Cloud115RapidView()
                } label: {
                    Label("云端秒传 / 转存", systemImage: "bolt.horizontal.circle")
                }
                JSONInspector(value: value)
            }
            .sheet(isPresented: $creating) {
                NavigationStack { UploadTaskEditorView(draft: UploadTaskDraft()) { reload.fire() } }
            }
            .sheet(item: $editing) { draft in
                NavigationStack { UploadTaskEditorView(draft: draft) { reload.fire() } }
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
            if let local = task.first(of: "local_folder").displayString {
                Text(local).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            HStack(spacing: 8) {
                Text("→ " + (task.first(of: "target_name", "target_path").displayString ?? "115"))
                Text("· " + (task.first(of: "watch_mode").displayString ?? "realtime"))
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            HStack(spacing: 14) {
                Button("扫描") {
                    runner.run("已触发扫描", operation: {
                        let api = try session.requireAPI()
                        return try await api.upload115.scanTask(taskId: id, .object(["force": .bool(true)]))
                    }, onSuccess: { await reload() })
                }
                Button("停止") {
                    runner.run("已停止", operation: {
                        let api = try session.requireAPI()
                        return try await api.upload115.stopTask(taskId: id)
                    }, onSuccess: { await reload() })
                }
                Button(enabled ? "停用" : "启用") {
                    runner.run("已更新", operation: {
                        let api = try session.requireAPI()
                        return try await api.upload115.toggleTask(taskId: id, TogglePayload(enabled: !enabled))
                    }, onSuccess: { await reload() })
                }
                Button("编辑") { editing = UploadTaskDraft(task) }
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .disabled(id.isEmpty)
            HStack(spacing: 14) {
                NavigationLink("查看进度") { UploadTaskStatusView(taskID: id, name: task.first(of: "name").string ?? "任务") }
                Button("删除") {
                    runner.run("已删除", operation: {
                        let api = try session.requireAPI()
                        return try await api.upload115.deleteTask(taskId: id)
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

/// 单个上传任务的实时状态与失败重试。
struct UploadTaskStatusView: View {
    let taskID: String
    let name: String

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    var body: some View {
        RemoteList(title: name) {
            let api = try session.requireAPI()
            return try await api.upload115.getTaskStatus(taskId: taskID)
        } content: { value, reload in
            Section("状态") {
                ForEach(value.sortedPairs.filter { $0.value.array == nil && $0.value.object == nil },
                        id: \.key) { pair in
                    KeyValueRow(pair.key, pair.value)
                }
            }
            let jobs = value.list("jobs", "files", "items", "records")
            Section("文件（\(jobs.count)）") {
                if jobs.isEmpty { EmptyRow("没有文件记录") }
                ForEach(Array(jobs.enumerated()), id: \.offset) { _, job in
                    jobRow(job, reload: reload)
                }
            }
            Section {
                Button {
                    runner.run("已清空", operation: {
                        let api = try session.requireAPI()
                        return try await api.upload115.clearHistory(taskId: taskID)
                    }, onSuccess: { await reload() })
                } label: {
                    Label("清空该任务历史", systemImage: "trash")
                }
                .foregroundStyle(.red)
                JSONInspector(value: value)
            }
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func jobRow(_ job: JSONValue, reload: Reload) -> some View {
        let jobID = job.first(of: "job_id", "id").displayString ?? ""
        let state = job.first(of: "status", "state").displayString
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(job.first(of: "name", "file_name", "path").displayString ?? "—")
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                if let state { StatusBadge(state, tone: badgeTone(for: state)) }
            }
            if job.first(of: "size", "file_size").double != nil {
                Text(Fmt.bytes(job.first(of: "size", "file_size")))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            if let message = job.first(of: "message", "error").displayString {
                Text(message).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            }
            if !jobID.isEmpty {
                HStack(spacing: 14) {
                    Button("重试") {
                        runner.run("已重试", operation: {
                            let api = try session.requireAPI()
                            return try await api.upload115.retryFile(taskId: taskID, RetryPayload(jobId: jobID))
                        }, onSuccess: { await reload() })
                    }
                    if isCancellableUploadJob(job) {
                        Button("取消上传") {
                            runner.run("已请求取消", operation: {
                                let api = try session.requireAPI()
                                return try await api.upload115.cancelFile(taskID: taskID, jobID: jobID)
                            }, onSuccess: { await reload() })
                        }
                    }
                    Button("删除记录") {
                        runner.run("已删除", operation: {
                            let api = try session.requireAPI()
                            return try await api.upload115.deleteHistoryRecord(
                                HistoryRecordPayload(status: state ?? "",
                                                     taskId: taskID,
                                                     jobId: jobID,
                                                     path: job.first(of: "path").string ?? "",
                                                     filename: job.first(of: "name", "file_name").string ?? ""))
                        }, onSuccess: { await reload() })
                    }
                    .foregroundStyle(.red)
                }
                .font(.caption2)
                .buttonStyle(.borderless)
            }
        }
    }
}

/// 上传并发设置。
struct UploadThreadSettingsView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var verify = 5
    @State private var rapid = 5
    @State private var upload = 5
    @State private var loaded = false

    var body: some View {
        Form {
            Section("并发数") {
                Stepper("校验并发 \(verify)", value: $verify, in: 1...30)
                Stepper("秒传并发 \(rapid)", value: $rapid, in: 1...30)
                Stepper("上传并发 \(upload)", value: $upload, in: 1...30)
            }
            Section {
                Button("保存") {
                    runner.run("已保存") {
                        let api = try session.requireAPI()
                        return try await api.upload115.updateThreadSettings(
                            UploadThreadSettingsPayload(verifyConcurrency: verify,
                                                        rapidConcurrency: rapid,
                                                        uploadConcurrency: upload))
                    }
                }
            } footer: {
                Text("并发过高可能触发 115 的风控限制，建议逐步调整。")
            }
        }
        .navigationTitle("并发设置")
        .actionFeedback(runner)
        .task {
            guard !loaded, let api = session.api else { return }
            loaded = true
            let value = await Probe.json { try await api.upload115.getThreadSettings() }
            verify = value.deepFirst(of: "verify_concurrency").int ?? 5
            rapid = value.deepFirst(of: "rapid_concurrency").int ?? 5
            upload = value.deepFirst(of: "upload_concurrency").int ?? 5
        }
    }
}

private func isCancellableUploadJob(_ job: JSONValue) -> Bool {
    let status = job.first(of: "status", "state").displayString?.lowercased() ?? ""
    let stage = job.first(of: "stage").displayString?.lowercased() ?? ""
    return ["active", "retrying"].contains(status)
        && !["success", "failed", "cancelled", "cancelling"].contains(stage)
}
