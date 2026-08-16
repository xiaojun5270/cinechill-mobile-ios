import SwiftUI

/// Emby 计划任务：运行、停止、查看/编辑触发器。
struct EmbyTasksView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    var body: some View {
        RemoteList(title: "Emby 任务中心", subtitle: "来自 Emby 服务器的计划任务") {
            let api = try session.requireAPI()
            return try await api.embyTasks.listEmbyTasks()
        } content: { value, reload in
            let tasks = value.list("tasks", "Items")
            if tasks.isEmpty {
                EmptyRow("没有读取到任务")
            }
            ForEach(Array(tasks.enumerated()), id: \.offset) { _, task in
                Section {
                    NavigationLink {
                        EmbyTaskDetailView(task: task)
                    } label: {
                        taskRow(task)
                    }
                    HStack(spacing: 16) {
                        Button {
                            act(task, run: true, reload: reload)
                        } label: {
                            Label("运行", systemImage: "play.fill")
                        }
                        Button {
                            act(task, run: false, reload: reload)
                        } label: {
                            Label("停止", systemImage: "stop.fill")
                        }
                        .foregroundStyle(.red)
                    }
                    .font(.subheadline)
                    .buttonStyle(.borderless)
                }
            }
        }
        .actionFeedback(runner)
    }

    private func taskRow(_ task: JSONValue) -> some View {
        let state = task.first(of: "State", "state", "status").displayString
        let progress = task.first(of: "CurrentProgressPercentage", "progress").double
        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(task.first(of: "Name", "name").displayString ?? "—")
                    .font(.subheadline.weight(.medium))
                Spacer()
                if let state { StatusBadge(state, tone: badgeTone(for: state)) }
            }
            if let description = task.first(of: "Description", "description").displayString {
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let progress, progress > 0, progress < 100 {
                ProgressView(value: min(max(progress / 100, 0), 1))
            }
            if let last = task.deepFirst(of: "LastExecutionResult", "last_result").first(of: "EndTimeUtc", "end_time").displayString {
                Text("上次结束 " + Fmt.relative(.string(last)))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func act(_ task: JSONValue, run: Bool, reload: Reload) {
        guard let id = task.first(of: "Id", "id").displayString else { return }
        runner.run(run ? "已触发" : "已请求停止", operation: {
            let api = try session.requireAPI()
            return run
                ? try await api.embyTasks.runEmbyTask(taskId: id)
                : try await api.embyTasks.stopEmbyTask(taskId: id)
        }, onSuccess: { await reload() })
    }
}

/// 任务详情与触发器编辑。
struct EmbyTaskDetailView: View {
    let task: JSONValue

    @EnvironmentObject private var session: AppSession

    private var taskID: String { task.first(of: "Id", "id").displayString ?? "" }

    var body: some View {
        Form {
            Section("任务") {
                KeyValueRow("名称", task.first(of: "Name", "name"))
                KeyValueRow("分类", task.first(of: "Category", "category"))
                KeyValueRow("状态", task.first(of: "State", "state"))
                KeyValueRow("ID", taskID, monospaced: true)
            }
            Section {
                NavigationLink {
                    EmbyTaskTriggersView(taskID: taskID)
                } label: {
                    Label("触发器设置", systemImage: "alarm")
                }
            }
        }
        .navigationTitle(task.first(of: "Name", "name").displayString ?? "任务")
    }
}

/// 触发器以数组形式返回，直接复用通用 JSON 编辑器。
struct EmbyTaskTriggersView: View {
    let taskID: String

    @EnvironmentObject private var session: AppSession

    var body: some View {
        JSONConfigScreen(
            title: "触发器",
            note: "触发器结构由 Emby 定义，常见字段为 Type（DailyTrigger / IntervalTrigger / StartupTrigger）与 TimeOfDayTicks。",
            unwrapKeys: ["triggers", "Triggers", "data"],
            load: {
                let api = try session.requireAPI()
                return try await api.embyTasks.getEmbyTaskTriggers(taskId: taskID)
            },
            save: { edited in
                let api = try session.requireAPI()
                let list = edited.array ?? edited.list("triggers", "Triggers")
                return try await api.embyTasks.updateEmbyTaskTriggers(
                    taskId: taskID, EmbyTaskTriggersPayload(triggers: list))
            })
    }
}
