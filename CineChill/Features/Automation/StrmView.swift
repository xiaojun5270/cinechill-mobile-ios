import SwiftUI

/// STRM 同步：任务列表、进度、配置编辑。
struct StrmView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    var body: some View {
        RemoteList(title: "STRM 同步", refreshOnAppear: true) {
            let api = try session.requireAPI()
            async let config = Probe.json { try await api.strm.getStrmConfig() }
            async let progress = Probe.json { try await api.strm.getStrmProgress() }
            let (config, progress) = await (config, progress)
            return JSONValue.object(["config": config, "progress": progress])
        } content: { value, reload in
            progressSection(value["progress"], reload: reload)

            let tasks = value["config"].deepFirst(of: "sync_tasks", "syncTasks").array ?? []
            Section("同步任务（\(tasks.count)）") {
                if tasks.isEmpty { EmptyRow("还没有同步任务，请在配置中新增") }
                ForEach(Array(tasks.enumerated()), id: \.offset) { index, task in
                    taskRow(task, index: index, reload: reload)
                }
            }

            Section {
                NavigationLink {
                    StrmConfigView()
                } label: {
                    Label("编辑同步配置", systemImage: "slider.horizontal.3")
                }
                JSONInspector(value: value)
            } footer: {
                Text("全量同步会遍历整个远端目录；增量+监控在首次同步后持续监听变化。元数据补齐只针对已有 STRM 文件抓取 TMDb 信息。")
            }
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func progressSection(_ progress: JSONValue, reload: Reload) -> some View {
        let runID = progress.deepFirst(of: "run_id", "runId").displayString ?? ""
        let running = progress.deepFirst(of: "running", "is_running").bool ?? false
        Section("进度") {
            HStack {
                Text("状态").foregroundStyle(.secondary)
                Spacer()
                StatusBadge(running ? "运行中" : "空闲", tone: running ? .good : .neutral)
            }
            if let total = progress.deepFirst(of: "total").double, total > 0 {
                let done = progress.deepFirst(of: "done", "current", "processed").double ?? 0
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: min(done / total, 1))
                    Text("\(Int(done)) / \(Int(total))")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            if let message = progress.deepFirst(of: "message", "stage", "status_text").displayString {
                Text(message).font(.caption).foregroundStyle(.secondary).lineLimit(3)
            }
            if running {
                Button("停止同步") {
                    runner.run("已请求停止", operation: {
                        let api = try session.requireAPI()
                        return try await api.strm.stopStrmSync(StrmStopPayload(runId: runID))
                    }, onSuccess: { await reload() })
                }
                .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private func taskRow(_ task: JSONValue, index: Int, reload: Reload) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(task.first(of: "name").displayString ?? "任务 \(index + 1)")
                .font(.subheadline.weight(.medium))
            if let remote = task.first(of: "remote_path").displayString {
                Text("远端 " + remote).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            if let local = task.first(of: "local_path").displayString {
                Text("本地 " + local).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            HStack(spacing: 8) {
                Text("网盘 #\(task.first(of: "drive_index").int ?? 0)")
                Text("· " + (task.first(of: "mode").displayString ?? "full"))
                Text("· 覆盖 " + (task.first(of: "overwrite").displayString ?? "skip"))
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            HStack(spacing: 14) {
                Button("全量") { start(index: index, mode: "full", reload: reload) }
                Button("增量+监控") { start(index: index, mode: "incremental", reload: reload) }
                Button("元数据") {
                    runner.run("已开始补齐", operation: {
                        let api = try session.requireAPI()
                        return try await api.strm.startStrmMetadataBackfill(
                            StrmStartPayload(taskIndex: index, mode: "metadata"))
                    }, onSuccess: { await reload() })
                }
            }
            .font(.caption)
            .buttonStyle(.borderless)
        }
    }

    private func start(index: Int, mode: String, reload: Reload) {
        runner.run("已开始同步", operation: {
            let api = try session.requireAPI()
            return try await api.strm.startStrmSync(StrmStartPayload(taskIndex: index, mode: mode))
        }, onSuccess: { await reload() })
    }
}

/// STRM 配置编辑：同步任务数组的通用编辑器。
struct StrmConfigView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        JSONConfigScreen(
            title: "STRM 配置",
            note: "sync_tasks 为同步任务数组。remote_path 为 115 目录，local_path 为服务器落地目录，strm_url_base 为播放地址前缀。",
            unwrapKeys: ["config", "data"],
            load: {
                let api = try session.requireAPI()
                return try await api.strm.getStrmConfig()
            },
            save: { edited in
                let api = try session.requireAPI()
                return try await api.strm.saveStrmConfig(try edited.decoded(StrmConfigPayload.self))
            })
    }
}
