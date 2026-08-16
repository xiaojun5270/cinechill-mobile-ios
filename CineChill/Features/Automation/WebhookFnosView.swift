import SwiftUI

/// Webhook：Emby 事件接入配置与队列。
struct WebhookView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var enabled = false
    @State private var engine = "classic"
    @State private var preset = ""
    @State private var mode = "random"
    @State private var deleteSync = true

    var body: some View {
        RemoteList(title: "Webhook", refreshOnAppear: true) {
            let api = try session.requireAPI()
            async let configRequest = Probe.json { try await api.webhook.getWebhookConfig() }
            async let queueRequest = Probe.json { try await api.webhook.getWebhookQueue() }
            let (config, queue) = await (configRequest, queueRequest)
            return JSONValue.object(["config": config, "queue": queue])
        } content: { value, reload in
            Section("配置") {
                Toggle("启用 Webhook", isOn: $enabled)
                Picker("引擎", selection: $engine) {
                    Text("经典").tag("classic")
                    Text("增强").tag("enhanced")
                }
                Picker("图片模式", selection: $mode) {
                    Text("随机").tag("random")
                    Text("固定").tag("fixed")
                }
                TextField("预设名称", text: $preset)
                    .textInputAutocapitalization(.never)
                Toggle("同步删除", isOn: $deleteSync)
                Button {
                    runner.run("已保存", operation: {
                        let api = try session.requireAPI()
                        return try await api.webhook.saveWebhookConfig(
                            WebhookConfigModel(enabled: enabled, engine: engine, preset: preset,
                                               mode: mode, deleteSyncEnabled: deleteSync))
                    }, onSuccess: { await reload() })
                } label: {
                    Label("保存配置", systemImage: "square.and.arrow.down")
                }
            }

            Section("接入地址") {
                Text(webhookURL)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                Button {
                    runner.run("已触发") {
                        let api = try session.requireAPI()
                        return try await api.webhook.embyWebhookTrigger()
                    }
                } label: {
                    Label("手动触发一次", systemImage: "bolt")
                }
            }

            let jobs = value["queue"].list("queue", "items", "jobs")
            Section("队列（\(jobs.count)）") {
                if jobs.isEmpty { EmptyRow("队列为空") }
                ForEach(Array(jobs.enumerated()), id: \.offset) { _, job in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(job.first(of: "title", "name", "event").displayString ?? "—")
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            if let state = job.first(of: "status", "state").displayString {
                                StatusBadge(state, tone: badgeTone(for: state))
                            }
                        }
                        if let time = job.first(of: "created_at", "time").displayString {
                            Text(Fmt.relative(.string(time)))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section { JSONInspector(value: value) }
                .task { apply(value["config"]) }
        }
        .actionFeedback(runner)
    }

    private var webhookURL: String {
        guard let base = session.activeServer?.baseURLString else { return "http://<服务器IP>:5256/api/webhook" }
        return base.hasSuffix("/") ? base + "api/webhook" : base + "/api/webhook"
    }

    private func apply(_ config: JSONValue) {
        enabled = config.deepFirst(of: "enabled").bool ?? enabled
        engine = config.deepFirst(of: "engine").string ?? engine
        preset = config.deepFirst(of: "preset").string ?? preset
        mode = config.deepFirst(of: "mode").string ?? mode
        deleteSync = config.deepFirst(of: "delete_sync_enabled").bool ?? deleteSync
    }
}

/// 飞牛（fnOS）签到。
struct FnosSignView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var enabled = false
    @State private var notify = true
    @State private var cookie = ""
    @State private var cron = "0 8 * * *"
    @State private var maxRetries = 3
    @State private var retryInterval = 30
    @State private var historyDays = 30

    var body: some View {
        RemoteList(title: "飞牛签到") {
            let api = try session.requireAPI()
            return try await api.fnosSign.getFnosSignState()
        } content: { value, reload in
            Section("状态") {
                KeyValueRow("今日签到", value.deepFirst(of: "signed_today", "today"))
                KeyValueRow("上次签到", value.deepFirst(of: "last_sign_at", "last_run"))
                KeyValueRow("连续天数", value.deepFirst(of: "streak", "continuous_days"))
                Button {
                    runner.run("已触发签到", operation: {
                        let api = try session.requireAPI()
                        return try await api.fnosSign.runFnosSign(FnosSignRunPayload(force: true))
                    }, onSuccess: { await reload() })
                } label: {
                    Label("立即签到", systemImage: "checkmark.seal")
                }
            }

            Section("配置") {
                Toggle("启用定时签到", isOn: $enabled)
                Toggle("推送通知", isOn: $notify)
                TextField("Cron", text: $cron)
                    .textInputAutocapitalization(.never)
                Text(Fmt.cron(cron)).font(.caption).foregroundStyle(.secondary)
                Stepper("重试次数 \(maxRetries)", value: $maxRetries, in: 0...10)
                Stepper("重试间隔 \(retryInterval) 秒", value: $retryInterval, in: 5...600, step: 5)
                Stepper("历史保留 \(historyDays) 天", value: $historyDays, in: 1...365)
            }

            Section("Cookie") {
                SecureField("fnOS Cookie", text: $cookie)
                Button {
                    runner.run("Cookie 有效") {
                        let api = try session.requireAPI()
                        return try await api.fnosSign.testFnosSignCookie(
                            FnosSignCookiePayload(cookie: cookie.isEmpty ? nil : cookie))
                    }
                } label: {
                    Label("测试 Cookie", systemImage: "bolt.horizontal")
                }
            }

            Section {
                Button {
                    runner.run("已保存", operation: {
                        let api = try session.requireAPI()
                        return try await api.fnosSign.updateFnosSignConfig(
                            FnosSignConfigPayload(enabled: enabled, notify: notify, cookie: cookie,
                                                  cron: cron, maxRetries: maxRetries,
                                                  retryInterval: retryInterval, historyDays: historyDays))
                    }, onSuccess: { await reload() })
                } label: {
                    Label("保存配置", systemImage: "square.and.arrow.down")
                }
                Button {
                    runner.run("已清空", operation: {
                        let api = try session.requireAPI()
                        return try await api.fnosSign.clearFnosSignHistory()
                    }, onSuccess: { await reload() })
                } label: {
                    Label("清空签到历史", systemImage: "trash")
                }
                .foregroundStyle(.red)
            }

            let history = value.list("history", "records", "items")
            Section("历史（\(history.count)）") {
                if history.isEmpty { EmptyRow("没有历史记录") }
                ForEach(Array(history.prefix(50).enumerated()), id: \.offset) { _, item in
                    HStack {
                        Text(item.first(of: "date", "time", "created_at").displayString ?? "—")
                            .font(.caption)
                        Spacer()
                        if let state = item.first(of: "status", "result").displayString {
                            StatusBadge(state, tone: badgeTone(for: state))
                        }
                    }
                }
            }

            Section { JSONInspector(value: value) }
                .task { apply(value) }
        }
        .actionFeedback(runner)
    }

    private func apply(_ value: JSONValue) {
        let config = value["config"].object != nil ? value["config"] : value
        enabled = config.deepFirst(of: "enabled").bool ?? enabled
        notify = config.deepFirst(of: "notify").bool ?? notify
        cron = config.deepFirst(of: "cron").string ?? cron
        maxRetries = config.deepFirst(of: "max_retries").int ?? maxRetries
        retryInterval = config.deepFirst(of: "retry_interval").int ?? retryInterval
        historyDays = config.deepFirst(of: "history_days").int ?? historyDays
    }
}
