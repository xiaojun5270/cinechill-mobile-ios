import SwiftUI

/// MoviePilot 站点、健康状态与新种监控。
struct MoviePilotSitesView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    var body: some View {
        RemoteList(title: "站点管理", subtitle: "MoviePilot 站点健康、发布监控与自动下载策略") {
            let api = try session.requireAPI()
            async let sites = api.moviePilot.getSites()
            async let config = api.moviePilot.getSiteMonitorConfig()
            async let status = api.moviePilot.getSiteMonitorStatus()
            let (sitesValue, configValue, statusValue) = try await (sites, config, status)
            return JSONValue.object([
                "sites": sitesValue,
                "config": configValue,
                "status": statusValue,
            ])
        } content: { value, reload in
            let sitesResponse = value["sites"]
            let sites = sitesResponse.list("items", "sites")
            let config = MoviePilotMonitorDraft(response: value["config"])
            let status = MoviePilotMonitorData(response: value["status"])

            summarySection(sitesResponse, sites: sites, monitored: config.monitoredCount)
            monitorSection(config: config, status: status, reload: reload)
            recentDownloadsSection(status.downloadTasks)
            sitesSection(sites, config: config, status: status, reload: reload)
            Section { JSONInspector(value: value) }
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func summarySection(_ response: JSONValue, sites: [JSONValue], monitored: Int) -> some View {
        let summary = response.deepFirst(of: "summary", "statistics", "stats")
        Section("概览") {
            KeyValueRow("站点总数", String(summary.first(of: "total").int ?? sites.count))
            KeyValueRow("正常可用", summary.first(of: "active", "available"))
            KeyValueRow("已监控", String(monitored))
            KeyValueRow("累计上传", Fmt.bytes(summary.first(of: "total_upload", "upload")))
            KeyValueRow("累计下载", Fmt.bytes(summary.first(of: "total_download", "download")))
            if let warning = response.first(of: "warning", "message").displayString, !warning.isEmpty {
                Text(warning).font(.footnote).foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private func monitorSection(config: MoviePilotMonitorDraft,
                                status: MoviePilotMonitorData,
                                reload: Reload) -> some View {
        Section {
            HStack {
                Text("状态")
                Spacer()
                StatusBadge(status.running ? "执行中" : (config.enabled ? "已启用" : "未启用"),
                            tone: status.running ? .info : (config.enabled ? .good : .neutral))
            }
            KeyValueRow("最近执行", Fmt.dateTime(status.lastRunAt))
            KeyValueRow("下次执行", config.enabled ? Fmt.dateTime(status.nextRunAt) : "监控未启用")
            NavigationLink {
                MoviePilotMonitorSettingsView()
            } label: {
                Label("监控设置", systemImage: "slider.horizontal.3")
            }
            Button {
                runner.run("已启动全部启用站点的监控") {
                    let api = try session.requireAPI()
                    return try await api.moviePilot.runSiteMonitor()
                } onSuccess: {
                    await reload()
                }
            } label: {
                Label("全部立即执行", systemImage: "play.fill")
            }
            .disabled(status.running || status.healthCheckRunning)
            Button {
                runner.run("已启动全部站点健康检查") {
                    let api = try session.requireAPI()
                    return try await api.moviePilot.checkSitesHealth()
                } onSuccess: {
                    await reload()
                }
            } label: {
                Label("全部健康检查", systemImage: "heart.text.square")
            }
            .disabled(status.running || status.healthCheckRunning)
        } header: {
            Text("新种监控")
        } footer: {
            Text("修改监控设置后需先保存；立即执行只处理已经启用监控的站点。")
        }
    }

    @ViewBuilder
    private func recentDownloadsSection(_ tasks: [JSONValue]) -> some View {
        Section("最近添加到下载器（\(tasks.count)）") {
            if tasks.isEmpty { EmptyRow("暂无已添加的下载任务") }
            ForEach(Array(tasks.prefix(100).enumerated()), id: \.offset) { _, task in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(task.first(of: "title", "torrent_title", "name").displayString ?? "—")
                            .font(.subheadline)
                            .lineLimit(2)
                        Spacer()
                        let decision = task.first(of: "decision", "event_type", "action", "status")
                            .displayString ?? "discovered"
                        StatusBadge(monitorDecisionLabel(decision), tone: badgeTone(for: decision))
                    }
                    HStack(spacing: 8) {
                        if let site = task.first(of: "site_name", "site", "source_name").displayString {
                            Text(site)
                        }
                        if task.first(of: "size", "size_bytes", "torrent_size").double != nil {
                            Text(Fmt.bytes(task.first(of: "size", "size_bytes", "torrent_size")))
                        }
                        if let time = task.first(of: "created_at", "timestamp", "time", "occurred_at").displayString {
                            Text(Fmt.relative(.string(time)))
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    if let reason = task.first(of: "reason", "message", "detail", "error").displayString,
                       !reason.isEmpty {
                        Text(reason).font(.caption2).foregroundStyle(.tertiary).lineLimit(2)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sitesSection(_ sites: [JSONValue],
                              config: MoviePilotMonitorDraft,
                              status: MoviePilotMonitorData,
                              reload: Reload) -> some View {
        Section("MoviePilot 站点（\(sites.count)）") {
            if sites.isEmpty { EmptyRow("MoviePilot 暂无可展示的站点") }
            ForEach(Array(sites.enumerated()), id: \.offset) { _, site in
                siteRow(site, config: config, status: status, reload: reload)
            }
        }
    }

    @ViewBuilder
    private func siteRow(_ site: JSONValue,
                         config: MoviePilotMonitorDraft,
                         status: MoviePilotMonitorData,
                         reload: Reload) -> some View {
        let id = site.first(of: "id", "site_id")
        let key = id.displayString ?? site.first(of: "domain").displayString ?? ""
        let siteConfig = config.site(key)
        let siteStatus = status.sites[key] ?? .null
        let health = MoviePilotMonitorData.health(siteStatus)
        let active = site.first(of: "is_active", "active", "enabled").bool ?? true
        let siteRunning = siteStatus.first(of: "running", "monitor_running").bool ?? false
        let siteChecking = siteStatus.first(of: "health_checking", "checking").bool ?? false

        VStack(alignment: .leading, spacing: 5) {
            NavigationLink {
                MoviePilotSiteDetailView(site: site)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(site.first(of: "name", "domain").displayString ?? "未命名站点")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        StatusBadge(health.label, tone: health.tone)
                    }
                    if let domain = site.first(of: "domain", "url").displayString {
                        Text(domain).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                    HStack(spacing: 8) {
                        Text(active ? "MP 已启用" : "MP 已停用")
                        Text(siteConfig.enabled ? "监控开启" : "监控关闭")
                        if siteConfig.washEnabled { Text("允许洗版") }
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    HStack(spacing: 8) {
                        Text("上传 " + Fmt.bytes(site.first(of: "upload")))
                        Text("下载 " + Fmt.bytes(site.first(of: "download")))
                        if let ratio = site.first(of: "ratio").double {
                            Text(String(format: "分享率 %.2f", ratio))
                        }
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 16) {
                Button("健康检查") {
                    runner.run("已启动站点健康检查") {
                        let api = try session.requireAPI()
                        return try await api.moviePilot.checkSitesHealth(siteIDs: [id])
                    } onSuccess: {
                        await reload()
                    }
                }
                .disabled(status.running || status.healthCheckRunning || siteRunning || siteChecking)
                Button("立即执行") {
                    runner.run("已启动站点监控") {
                        let api = try session.requireAPI()
                        return try await api.moviePilot.runSiteMonitor(siteIDs: [id])
                    } onSuccess: {
                        await reload()
                    }
                }
                .disabled(!siteConfig.enabled || status.running || status.healthCheckRunning
                          || siteRunning || siteChecking)
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .disabled(key.isEmpty || id.isNull || !active)
        }
    }
}

/// 全局监控设置。站点开关保留在原始配置中，不会因保存全局字段而丢失。
struct MoviePilotMonitorSettingsView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var draft = MoviePilotMonitorDraft()
    @State private var loading = true
    @State private var failure: String?

    var body: some View {
        Form {
            if loading {
                LoadingRow()
            } else if let failure {
                FailureRow(message: failure) { Task { await load() } }
            } else {
                Section("调度") {
                    Toggle("启用定时监控", isOn: $draft.enabled)
                    TextField("轮询间隔（分钟）", value: $draft.intervalMinutes, format: .number)
                        .keyboardType(.numberPad)
                    if draft.intervalMinutes < 15 {
                        Text("轮询间隔不能短于 15 分钟。")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                Section("下载策略") {
                    Toggle("自动下载缺失媒体", isOn: $draft.autoDownload)
                    Toggle("全局允许洗版", isOn: $draft.washEnabled)
                    Toggle("排除 H&R", isOn: $draft.excludeHR)
                }
                Section {
                    Button("保存监控设置") { save() }
                        .disabled(draft.intervalMinutes < 15)
                } footer: {
                    Text("已保留 \(draft.siteConfigs.count) 个站点的独立开关；洗版还需要在对应站点中开启。")
                }
            }
        }
        .navigationTitle("监控设置")
        .actionFeedback(runner)
        .task { await load() }
    }

    private func load() async {
        guard let api = session.api else {
            failure = "请先登录服务器"
            loading = false
            return
        }
        loading = true
        failure = nil
        do {
            draft = MoviePilotMonitorDraft(response: try await api.moviePilot.getSiteMonitorConfig())
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            failure = error.errorDescription
        } catch {
            failure = error.localizedDescription
        }
        loading = false
    }

    private func save() {
        runner.run("站点监控设置已保存") {
            let api = try session.requireAPI()
            return try await api.moviePilot.updateSiteMonitorConfig(draft.payload)
        } onSuccess: {
            await load()
        }
    }
}

/// 单站监控与洗版设置。
struct MoviePilotSiteDetailView: View {
    let site: JSONValue

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var config = MoviePilotMonitorDraft()
    @State private var enabled = false
    @State private var washEnabled = false
    @State private var status: JSONValue = .null
    @State private var globalRunning = false
    @State private var globalHealthCheckRunning = false
    @State private var loading = true
    @State private var failure: String?

    private var siteID: JSONValue { site.first(of: "id", "site_id") }
    private var siteKey: String {
        siteID.displayString ?? site.first(of: "domain").displayString ?? ""
    }

    var body: some View {
        Form {
            if loading {
                LoadingRow()
            } else if let failure {
                FailureRow(message: failure) { Task { await load() } }
            } else {
                Section("站点") {
                    KeyValueRow("名称", site.first(of: "name", "domain"))
                    KeyValueRow("域名", site.first(of: "domain", "url"))
                    KeyValueRow("上传", Fmt.bytes(site.first(of: "upload")))
                    KeyValueRow("下载", Fmt.bytes(site.first(of: "download")))
                    let health = MoviePilotMonitorData.health(status)
                    HStack {
                        Text("健康状态")
                        Spacer()
                        StatusBadge(health.label, tone: health.tone)
                    }
                    if let message = status.first(of: "message", "error", "last_error").displayString,
                       !message.isEmpty {
                        Text(message).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("监控") {
                    Toggle("站点监控", isOn: $enabled)
                    Toggle("允许洗版", isOn: $washEnabled)
                    Button("保存站点设置") { save() }
                }
                Section("操作") {
                    Button {
                        runHealthCheck()
                    } label: {
                        Label("健康检查", systemImage: "heart.text.square")
                    }
                    .disabled(siteID.isNull || operationRunning)
                    Button {
                        runMonitor()
                    } label: {
                        Label("立即执行", systemImage: "play.fill")
                    }
                    .disabled(!enabled || siteID.isNull || operationRunning)
                }
            }
        }
        .navigationTitle(site.first(of: "name", "domain").displayString ?? "站点")
        .actionFeedback(runner)
        .task { await load() }
    }

    private func load() async {
        guard let api = session.api else {
            failure = "请先登录服务器"
            loading = false
            return
        }
        loading = true
        failure = nil
        do {
            async let configResponse = api.moviePilot.getSiteMonitorConfig()
            async let statusResponse = api.moviePilot.getSiteMonitorStatus()
            let (configValue, statusValue) = try await (configResponse, statusResponse)
            let loadedConfig = MoviePilotMonitorDraft(response: configValue)
            let loadedStatus = MoviePilotMonitorData(response: statusValue)
            config = loadedConfig
            let siteConfig = loadedConfig.site(siteKey)
            enabled = siteConfig.enabled
            washEnabled = siteConfig.washEnabled
            status = loadedStatus.sites[siteKey] ?? .null
            globalRunning = loadedStatus.running
            globalHealthCheckRunning = loadedStatus.healthCheckRunning
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            failure = error.errorDescription
        } catch {
            failure = error.localizedDescription
        }
        loading = false
    }

    private var operationRunning: Bool {
        globalRunning || globalHealthCheckRunning
            || status.first(of: "running", "monitor_running").bool == true
            || status.first(of: "health_checking", "checking").bool == true
    }

    private func save() {
        var updated = config
        updated.setSite(siteKey, enabled: enabled, washEnabled: washEnabled)
        runner.run("站点设置已保存") {
            let api = try session.requireAPI()
            return try await api.moviePilot.updateSiteMonitorConfig(updated.payload)
        } onSuccess: {
            await load()
        }
    }

    private func runHealthCheck() {
        runner.run("已启动站点健康检查") {
            let api = try session.requireAPI()
            return try await api.moviePilot.checkSitesHealth(siteIDs: [siteID])
        } onSuccess: {
            await load()
        }
    }

    private func runMonitor() {
        runner.run("已启动站点监控") {
            let api = try session.requireAPI()
            return try await api.moviePilot.runSiteMonitor(siteIDs: [siteID])
        } onSuccess: {
            await load()
        }
    }
}

struct MoviePilotMonitorDraft: Hashable {
    var enabled = false
    var intervalMinutes = 15
    var autoDownload = false
    var washEnabled = false
    var excludeHR = true
    var siteConfigs: [String: JSONValue] = [:]

    init() {}

    init(response: JSONValue) {
        let node = Self.unwrap(response)
        enabled = node.first(of: "enabled", "monitor_enabled").bool ?? false
        intervalMinutes = max(15, node.first(of: "interval_minutes", "poll_interval_minutes").int ?? 15)
        autoDownload = node.first(of: "auto_download", "auto_download_enabled").bool ?? false
        washEnabled = node.first(of: "wash_enabled", "auto_wash_enabled").bool ?? false
        excludeHR = node.first(of: "exclude_hr", "exclude_hit_and_run").bool ?? true
        siteConfigs = Self.keyed(node.first(of: "sites", "site_configs"))
    }

    var monitoredCount: Int { siteConfigs.values.filter { Self.site($0).enabled }.count }

    var payload: JSONValue {
        .object([
            "enabled": .bool(enabled),
            "interval_minutes": .int(max(15, intervalMinutes)),
            "auto_download": .bool(autoDownload),
            "wash_enabled": .bool(washEnabled),
            "exclude_hr": .bool(excludeHR),
            "sites": .object(siteConfigs),
        ])
    }

    func site(_ key: String) -> (enabled: Bool, washEnabled: Bool) {
        Self.site(siteConfigs[key] ?? .null)
    }

    mutating func setSite(_ key: String, enabled: Bool, washEnabled: Bool) {
        guard !key.isEmpty else { return }
        var node = siteConfigs[key]?.object ?? [:]
        node["enabled"] = .bool(enabled)
        node["wash_enabled"] = .bool(washEnabled)
        siteConfigs[key] = .object(node)
    }

    private static func site(_ node: JSONValue) -> (enabled: Bool, washEnabled: Bool) {
        (node.first(of: "enabled", "monitor_enabled").bool ?? false,
         node.first(of: "wash_enabled", "auto_wash_enabled").bool ?? false)
    }

    private static func unwrap(_ response: JSONValue) -> JSONValue {
        for key in ["config", "data"] where response[key].object != nil { return response[key] }
        return response
    }

    static func keyed(_ value: JSONValue) -> [String: JSONValue] {
        if let object = value.object { return object }
        var result: [String: JSONValue] = [:]
        for item in value.array ?? [] {
            if let id = item.first(of: "site_id", "id").displayString, !id.isEmpty {
                result[id] = item
            }
        }
        return result
    }
}

struct MoviePilotMonitorData {
    var running = false
    var healthCheckRunning = false
    var lastRunAt: JSONValue = .null
    var nextRunAt: JSONValue = .null
    var sites: [String: JSONValue] = [:]
    var downloadTasks: [JSONValue] = []

    init(response: JSONValue) {
        var node = response
        for key in ["status", "data"] where response[key].object != nil {
            node = response[key]
            break
        }
        running = node.first(of: "running", "monitor_running").bool ?? false
        healthCheckRunning = node.first(of: "health_check_running", "checking_health").bool ?? false
        lastRunAt = node.first(of: "last_run_at", "checked_at")
        nextRunAt = node.first(of: "next_run_at", "scheduled_at")
        sites = MoviePilotMonitorDraft.keyed(node.first(of: "sites", "site_statuses"))
        let tasks = node.first(of: "download_tasks", "recent_download_tasks")
        downloadTasks = tasks.array ?? tasks.list("items")
    }

    static func health(_ status: JSONValue) -> (label: String, tone: BadgeTone) {
        if status.first(of: "health_checking", "checking").bool == true {
            return ("检查中", .info)
        }
        let nested = status["health"]
        let raw = (status.first(of: "health", "health_status").displayString
                   ?? nested.first(of: "status", "state").displayString
                   ?? "unknown").lowercased()
        if ["healthy", "ok", "success", "available"].contains(raw) { return ("健康", .good) }
        if ["unhealthy", "error", "failed", "unavailable"].contains(raw) { return ("不健康", .bad) }
        return ("未检查", .neutral)
    }
}

private func monitorDecisionLabel(_ value: String) -> String {
    switch value.lowercased() {
    case "missing_download", "missing_library": return "缺库待下载"
    case "downloaded": return "已添加下载"
    case "wash_downloaded": return "已添加洗版下载"
    case "wash_candidate", "wash_candidates": return "洗版候选"
    case "existing_library": return "已在媒体库"
    case "hr_skipped": return "H&R 已排除"
    case "failed", "error": return "错误"
    case "skipped": return "已跳过"
    default: return value == "discovered" ? "发现新种" : value
    }
}
