import SwiftUI

/// Docker 管理：容器、镜像、仓库凭据。
struct DockerView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var runIDInput = ""

    private var trimmedRunID: String { runIDInput.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        RemoteList(title: "Docker") {
            let api = try session.requireAPI()
            let status = await Probe.json { try await api.docker.dockerStatus() }
            let containers = await Probe.json { try await api.docker.listContainers() }
            return JSONValue.object(["status": status, "containers": containers])
        } content: { value, reload in
            Section("状态") {
                KeyValueRow("可用", value["status"].deepFirst(of: "available", "ok", "connected"))
                KeyValueRow("版本", value["status"].deepFirst(of: "version", "server_version"))
                if let message = value["status"].deepFirst(of: "message", "error").displayString {
                    Text(message).font(.caption).foregroundStyle(.secondary)
                }
            }

            let containers = value["containers"].list("containers", "items", "data")
            Section("容器（\(containers.count)）") {
                if containers.isEmpty { EmptyRow("没有容器") }
                ForEach(Array(containers.enumerated()), id: \.offset) { _, container in
                    containerRow(container, reload: reload)
                }
            }

            updateTaskSection

            Section {
                Button {
                    runner.run("已提交检查") {
                        let api = try session.requireAPI()
                        let images = containers.compactMap { $0.first(of: "image").string }
                        return try await api.docker.checkContainerUpdates(
                            CheckUpdatesPayload(images: images.map { JSONValue.string($0) }))
                    }
                } label: {
                    Label("检查镜像更新", systemImage: "arrow.down.circle")
                }
                NavigationLink {
                    DockerImagesView()
                } label: {
                    Label("镜像管理", systemImage: "shippingbox")
                }
                NavigationLink {
                    DockerRegistryView()
                } label: {
                    Label("仓库凭据", systemImage: "key")
                }
                JSONInspector(value: value)
            }
        }
        .actionFeedback(runner)
    }

    /// 「更新镜像」返回的 run_id 可用于查询更新任务进度。
    @ViewBuilder
    private var updateTaskSection: some View {
        let detected = runner.lastResult.deepFirst(of: "run_id", "update_run_id", "task_id").displayString ?? ""
        Section {
            if !detected.isEmpty {
                KeyValueRow("最近 run_id", detected, monospaced: true)
                NavigationLink {
                    DockerUpdateTaskView(runID: detected)
                } label: {
                    Label("查看最近的更新任务", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            TextField("手动输入 run_id", text: $runIDInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            NavigationLink {
                DockerUpdateTaskView(runID: trimmedRunID)
            } label: {
                Label("查看该任务状态", systemImage: "doc.text.magnifyingglass")
            }
            .disabled(trimmedRunID.isEmpty)
        } header: {
            Text("镜像更新任务")
        } footer: {
            Text("点击容器的「更新镜像」后，服务端会返回一个 run_id，这里可以查看该次更新的执行状态与日志。")
        }
    }

    @ViewBuilder
    private func containerRow(_ container: JSONValue, reload: Reload) -> some View {
        let id = container.first(of: "id", "Id", "container_id").displayString ?? ""
        let state = container.first(of: "state", "status", "State").displayString
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(container.first(of: "name", "Name", "names").displayString ?? "—")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                if let state { StatusBadge(state, tone: badgeTone(for: state)) }
            }
            if let image = container.first(of: "image", "Image").displayString {
                Text(image).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            if container.first(of: "update_available", "has_update").bool == true {
                StatusBadge("有更新", tone: .warning)
            }
            HStack(spacing: 14) {
                Button("启动") { action("start", id: id, reload: reload) }
                Button("停止") { action("stop", id: id, reload: reload) }
                Button("重启") { action("restart", id: id, reload: reload) }
                NavigationLink("日志") {
                    DockerLogsView(containerID: id,
                                   name: container.first(of: "name", "Name").string ?? "容器")
                }
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .disabled(id.isEmpty)
            HStack(spacing: 14) {
                NavigationLink("更新设置") {
                    DockerContainerSettingsView(
                        containerID: id,
                        name: container.first(of: "name", "Name").string ?? "容器",
                        image: container.first(of: "image", "Image").string ?? "")
                }
                Button("更新镜像") { action("update", id: id, reload: reload) }
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .disabled(id.isEmpty)
        }
    }

    private func action(_ name: String, id: String, reload: Reload) {
        runner.run("已执行", operation: {
            let api = try session.requireAPI()
            return try await api.docker.containerAction(containerId: id,
                                                        ContainerActionPayload(action: name))
        }, onSuccess: { await reload() })
    }
}

/// 容器日志。
struct DockerLogsView: View {
    let containerID: String
    let name: String

    @EnvironmentObject private var session: AppSession
    @State private var tail = 200
    @State private var queryKey = 0

    var body: some View {
        RemoteList(title: name) {
            let api = try session.requireAPI()
            return try await api.docker.containerLogs(containerId: containerID, tail: tail)
        } content: { value, _ in
            Section {
                Stepper("显示最近 \(tail) 行", value: $tail, in: 50...2000, step: 50)
                    .onChange(of: tail) { _, _ in queryKey += 1 }
            }
            let lines = logLines(value)
            Section("日志（\(lines.count)）") {
                if lines.isEmpty { EmptyRow("没有日志") }
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .id(queryKey)
    }

    private func logLines(_ value: JSONValue) -> [String] {
        if let text = value.deepFirst(of: "logs", "log", "output").string {
            return text.split(separator: "\n").map(String.init)
        }
        let list = value.list("logs", "lines", "items")
        if !list.isEmpty { return list.compactMap { $0.displayString } }
        if let text = value.string { return text.split(separator: "\n").map(String.init) }
        return []
    }
}

/// 容器镜像更新任务（run_id）的执行状态与日志。
struct DockerUpdateTaskView: View {
    let runID: String

    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "更新任务") {
            let api = try session.requireAPI()
            return try await api.docker.getUpdateTask(runId: runID)
        } content: { value, reload in
            overviewSection(value)
            stepsSection(value)
            Section {
                Button {
                    reload.fire()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                JSONInspector(value: value)
            } footer: {
                Text("更新任务在服务端异步执行，下拉或点击刷新可获取最新状态。")
            }
        }
    }

    @ViewBuilder
    private func overviewSection(_ value: JSONValue) -> some View {
        let state = value.deepFirst(of: "status", "state", "phase").displayString
        let progress = value.deepFirst(of: "progress", "percent", "percentage")
        Section("概览") {
            KeyValueRow("run_id", runID, monospaced: true)
            if let state {
                HStack {
                    Text("状态").foregroundStyle(.secondary)
                    Spacer()
                    StatusBadge(state, tone: badgeTone(for: state))
                }
            }
            KeyValueRow("容器", value.deepFirst(of: "container_name", "container", "name"))
            KeyValueRow("镜像", value.deepFirst(of: "image", "target_image"))
            KeyValueRow("开始时间", Fmt.dateTime(value.deepFirst(of: "started_at", "start_time", "created_at")))
            KeyValueRow("结束时间", Fmt.dateTime(value.deepFirst(of: "finished_at", "end_time", "updated_at")))
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
    private func stepsSection(_ value: JSONValue) -> some View {
        let steps = value.list("steps", "logs", "events", "items")
        Section("执行记录（\(steps.count)）") {
            if steps.isEmpty { EmptyRow("暂无执行记录") }
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                if let text = step.displayString {
                    Text(text)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                } else {
                    stepRow(step)
                }
            }
        }
    }

    @ViewBuilder
    private func stepRow(_ step: JSONValue) -> some View {
        let state = step.first(of: "status", "state", "result").displayString
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(step.first(of: "name", "step", "title", "message").displayString ?? "—")
                    .font(.caption)
                    .lineLimit(2)
                Spacer()
                if let state { StatusBadge(state, tone: badgeTone(for: state)) }
            }
            if let detail = step.first(of: "detail", "error", "output").displayString {
                Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(3)
            }
        }
    }
}

/// 容器的自动更新 / 定时重启 / Compose 镜像设置。
struct DockerContainerSettingsView: View {
    let containerID: String
    let name: String
    let image: String

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var autoUpdate = false
    @State private var ignoreUpdate = false
    @State private var composeImage = ""
    @State private var restartEnabled = false
    @State private var restartMode = "time"
    @State private var restartTime = "04:00"
    @State private var memoryLimit = 0.0
    @State private var memoryMinutes = 15.0
    @State private var prepared = false
    @State private var iconURL = ""
    @State private var resolvedIcon: URL?

    var body: some View {
        Form {
            Section("镜像更新") {
                Toggle("自动更新", isOn: $autoUpdate)
                Toggle("忽略此镜像的更新提示", isOn: $ignoreUpdate)
                TextField("Compose 镜像", text: $composeImage)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("保存更新设置") { saveUpdateSettings() }
            }
            Section("定时重启") {
                Toggle("启用", isOn: $restartEnabled)
                Picker("触发方式", selection: $restartMode) {
                    Text("按时间").tag("time")
                    Text("按内存").tag("memory")
                }
                if restartMode == "time" {
                    TextField("时间（HH:mm）", text: $restartTime)
                        .textInputAutocapitalization(.never)
                } else {
                    Stepper("内存上限 \(Int(memoryLimit)) MB", value: $memoryLimit, in: 0...65536, step: 128)
                    Stepper("持续 \(Int(memoryMinutes)) 分钟", value: $memoryMinutes, in: 1...240)
                }
                Button("保存重启策略") { saveRestart(scheduled: true) }
                Button("保存为自动重启策略") { saveRestart(scheduled: false) }
            }
            Section("图标") {
                TextField("项目地址 / 图标来源 URL", text: $iconURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("解析图标") { resolveIcon() }
                    .disabled(runner.isRunning || iconURL.trimmingCharacters(in: .whitespaces).isEmpty)
                if let resolved = resolvedIcon {
                    HStack(spacing: 12) {
                        AsyncImage(url: resolved) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fit)
                            } else {
                                Color.secondary.opacity(0.15)
                            }
                        }
                        .frame(width: 40, height: 40)
                        Text(resolved.absoluteString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .navigationTitle(name)
        .actionFeedback(runner)
        .task {
            guard !prepared else { return }
            prepared = true
            composeImage = image
        }
    }

    private func saveUpdateSettings() {
        runner.run("已保存") {
            let api = try session.requireAPI()
            _ = try await api.docker.setContainerAutoUpdate(
                containerId: containerID, AutoUpdatePayload(enabled: autoUpdate, image: composeImage))
            _ = try await api.docker.setContainerIgnoreUpdate(
                containerId: containerID, IgnoreUpdatePayload(ignored: ignoreUpdate))
            if !composeImage.isEmpty {
                _ = try await api.docker.setContainerComposeImage(
                    containerId: containerID, ComposeImagePayload(image: composeImage))
            }
            return .object(["success": .bool(true)])
        }
    }

    private func saveRestart(scheduled: Bool) {
        runner.run("已保存") {
            let api = try session.requireAPI()
            let payload = ScheduledRestartPayload(enabled: restartEnabled, mode: restartMode,
                                                  time: restartTime, memoryLimitMb: memoryLimit,
                                                  memoryDurationMinutes: memoryMinutes)
            if scheduled {
                return try await api.docker.setContainerScheduledRestart(containerId: containerID, payload)
            }
            return try await api.docker.setContainerAutoRestart(containerId: containerID, payload)
        }
    }

    /// 图标解析：接口返回的可能是完整 URL，也可能是服务端相对路径。
    private func resolveIcon() {
        let raw = iconURL.trimmingCharacters(in: .whitespaces)
        runner.run(nil, operation: {
            let api = try session.requireAPI()
            return try await api.docker.resolveContainerIcon(ResolveIconPayload(url: raw))
        }, onSuccess: {
            let text = runner.lastResult.deepFirst(of: "icon", "icon_url", "url", "logo").displayString
            if let text, !text.isEmpty {
                resolvedIcon = text.hasPrefix("http") ? URL(string: text) : session.absoluteURL(text)
            } else {
                resolvedIcon = nil
            }
        })
    }
}
