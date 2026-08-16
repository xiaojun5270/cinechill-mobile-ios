import SwiftUI

/// 仪表盘：媒体库总览、设备状态、115 账号、任务动态。
/// 服务端未声明响应结构，因此所有取值都用候选键名兜底，并保留「原始数据」入口。
struct DashboardView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteScroll(title: "仪表盘") {
            let api = try session.requireAPI()
            let stats = await Probe.json { try await api.server.getDashboardStats() }
            let metrics = await Probe.json { try await api.server.getDashboardDeviceMetrics() }
            let drive = await Probe.json { try await api.server.getDashboard115Account() }
            let progress = await Probe.json { try await api.tasks.getProgress() }
            let health = await Probe.json { try await api.health.getSystemHealth() }
            return JSONValue.object([
                "stats": stats,
                "metrics": metrics,
                "drive115": drive,
                "progress": progress,
                "health": health,
            ])
        } content: { value, reload in
            greeting
            FavoriteModulesCard()
            libraryOverview(value["stats"])
            deviceCard(value["metrics"])
            drive115Card(value["drive115"])
            taskCard(value["progress"])
            librariesCard(value["stats"])
            recentCard(value["stats"])
            rawCard(value, reload: reload)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ModuleSearchView()
                } label: {
                    Label("全部功能", systemImage: "magnifyingglass")
                }
            }
        }
    }

    // MARK: - 顶部问候

    private var greeting: some View {
        CardSection(title: session.activeServer?.displayName ?? "CineChill",
                    systemImage: "sparkles") {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(salutation)，\(session.displayUsername)")
                    .font(.title3.weight(.semibold))
                Text("好内容不怕晚一点抵达，稳定才是长久的浪漫。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    if let version = session.serverVersion {
                        StatusBadge("v\(version)", tone: .info)
                    }
                    if let host = session.activeServer?.baseURLString {
                        Text(host)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var salutation: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "上午好"
        case 11..<14: return "午间好"
        case 14..<18: return "下午好"
        case 18..<23: return "晚上好"
        default: return "夜深了"
        }
    }

    // MARK: - 媒体库总览

    @ViewBuilder
    private func libraryOverview(_ stats: JSONValue) -> some View {
        let movies = stats.deepFirst(of: "movie_count", "movies", "MovieCount", "total_movies")
        let series = stats.deepFirst(of: "series_count", "series", "SeriesCount", "tv_count", "shows")
        let episodes = stats.deepFirst(of: "episode_count", "episodes", "EpisodeCount")
        let users = stats.deepFirst(of: "user_count", "users_count", "users", "UserCount")

        if !stats.isNull {
            CardSection(title: "媒体库总览", systemImage: "square.stack.3d.up") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MetricTile(title: "电影", value: countText(movies), systemImage: "film", tone: .info)
                    MetricTile(title: "电视剧", value: countText(series), systemImage: "tv", tone: .good)
                    MetricTile(title: "剧集", value: countText(episodes), systemImage: "list.and.film", tone: .warning)
                    MetricTile(title: "用户", value: countText(users), systemImage: "person.2", tone: .neutral)
                }
            }
        }
    }

    private func countText(_ value: JSONValue) -> String {
        if let i = value.int { return i >= 10000 ? Fmt.count(value) : String(i) }
        if let list = value.array { return String(list.count) }
        return "—"
    }

    // MARK: - 设备状态

    @ViewBuilder
    private func deviceCard(_ metrics: JSONValue) -> some View {
        if !metrics.isNull {
            let cpu = metrics.deepFirst(of: "cpu")
            let memory = metrics.deepFirst(of: "memory", "mem", "ram")
            let disk = metrics.deepFirst(of: "disk", "storage")
            let network = metrics.deepFirst(of: "network", "net")
            let uptime = metrics.deepFirst(of: "uptime", "uptime_seconds", "boot_seconds")

            CardSection(title: "服务器状态", systemImage: "cpu",
                        trailing: AnyView(uptimeBadge(uptime))) {
                VStack(alignment: .leading, spacing: 12) {
                    GaugeRow(title: "CPU",
                             ratio: Fmt.ratio(ratioValue(cpu)),
                             caption: Fmt.percent(ratioValue(cpu), digits: 0))
                    if let model = cpu.first(of: "model", "name", "brand").string {
                        Text(model).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                    GaugeRow(title: "内存",
                             ratio: Fmt.ratio(ratioValue(memory)),
                             caption: usedTotalText(memory))
                    GaugeRow(title: "硬盘",
                             ratio: Fmt.ratio(ratioValue(disk)),
                             caption: usedTotalText(disk))
                    HStack {
                        Label("上行 " + Fmt.speed(network.first(of: "upload", "up", "tx", "sent")),
                              systemImage: "arrow.up")
                        Spacer()
                        Label("下行 " + Fmt.speed(network.first(of: "download", "down", "rx", "recv")),
                              systemImage: "arrow.down")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func uptimeBadge(_ uptime: JSONValue) -> some View {
        Group {
            if let seconds = uptime.double, seconds > 0 {
                StatusBadge("运行 " + Fmt.duration(seconds: seconds), tone: .good)
            } else if let text = uptime.string, !text.isEmpty {
                StatusBadge(text, tone: .good)
            }
        }
    }

    /// 兼容 `{percent: 66}`、`{usage: 0.66}` 与直接给数字两种形态。
    private func ratioValue(_ node: JSONValue) -> JSONValue {
        if node.object != nil {
            return node.first(of: "percent", "percentage", "usage", "used_percent", "ratio", "load")
        }
        return node
    }

    private func usedTotalText(_ node: JSONValue) -> String {
        let used = node.first(of: "used", "used_bytes", "used_gb")
        let total = node.first(of: "total", "total_bytes", "total_gb", "size")
        if let text = node.first(of: "text", "summary").string { return text }
        guard used.double != nil || total.double != nil else {
            return Fmt.percent(ratioValue(node), digits: 0)
        }
        let scale: Double = (node["used_gb"].double != nil) ? 1024 * 1024 * 1024 : 1
        let usedBytes = used.double.map { $0 * scale }
        let totalBytes = total.double.map { $0 * scale }
        return "\(Fmt.bytes(usedBytes)) / \(Fmt.bytes(totalBytes))"
    }

    // MARK: - 115 账号

    @ViewBuilder
    private func drive115Card(_ drive: JSONValue) -> some View {
        if !drive.isNull, !drive.isEmptyContainer {
            CardSection(title: "115 网盘", systemImage: "externaldrive.badge.icloud") {
                VStack(spacing: 8) {
                    if let name = drive.deepFirst(of: "user_name", "username", "name").displayString {
                        KeyValueRow("账号", name)
                    }
                    let used = drive.deepFirst(of: "used", "used_size", "space_used")
                    let total = drive.deepFirst(of: "total", "total_size", "all_total", "space_total")
                    if used.double != nil || total.double != nil {
                        KeyValueRow("空间", "\(Fmt.bytes(used)) / \(Fmt.bytes(total))")
                    }
                    if let vip = drive.deepFirst(of: "vip_name", "vip", "is_vip").displayString {
                        KeyValueRow("会员", vip)
                    }
                    NavigationLink {
                        JSONRawScreen(value: drive, title: "115 账号")
                    } label: {
                        Label("查看详情", systemImage: "chevron.right.circle")
                            .font(.caption)
                    }
                }
            }
        }
    }

    // MARK: - 任务动态

    @ViewBuilder
    private func taskCard(_ progress: JSONValue) -> some View {
        let running = progress.list("running", "tasks").filter { item in
            let status = item.first(of: "status", "state").string?.lowercased() ?? ""
            return status.isEmpty || !["done", "finished", "completed", "idle"].contains(status)
        }
        CardSection(title: "任务动态", systemImage: "bolt.horizontal") {
            VStack(alignment: .leading, spacing: 8) {
                if running.isEmpty {
                    Text("当前没有运行中的任务")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(running.prefix(5).enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.first(of: "name", "title", "task", "id").displayString ?? "任务")
                                    .font(.subheadline)
                                Spacer()
                                StatusBadge(item.first(of: "status", "state").displayString ?? "运行中",
                                            tone: badgeTone(for: item.first(of: "status", "state").string))
                            }
                            if let percent = item.first(of: "percent", "progress", "ratio").double {
                                ProgressView(value: Fmt.ratio(.double(percent)))
                            }
                            if let message = item.first(of: "message", "current", "detail").string {
                                Text(message).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                    }
                }
                NavigationLink {
                    TaskCenterView()
                } label: {
                    Label("任务中心", systemImage: "list.bullet.rectangle").font(.caption)
                }
            }
        }
    }

    // MARK: - 媒体库明细

    @ViewBuilder
    private func librariesCard(_ stats: JSONValue) -> some View {
        let libraries = stats.deepFirst(of: "libraries", "library_list", "views", "items").array ?? []
        if !libraries.isEmpty {
            CardSection(title: "媒体库", systemImage: "rectangle.stack") {
                VStack(spacing: 6) {
                    ForEach(Array(libraries.prefix(20).enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text(item.first(of: "name", "Name", "title").displayString ?? "—")
                                .font(.subheadline)
                            Spacer()
                            Text(countText(item.first(of: "count", "total", "item_count", "ItemCount")) + " 部")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 最近入库

    @ViewBuilder
    private func recentCard(_ stats: JSONValue) -> some View {
        let recent = stats.deepFirst(of: "recent_items", "recently_added", "latest", "recent").array ?? []
        if !recent.isEmpty {
            CardSection(title: "最近入库", systemImage: "clock.arrow.circlepath") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(recent.prefix(24).enumerated()), id: \.offset) { _, item in
                            PosterCard(
                                title: item.first(of: "name", "title", "Name").displayString ?? "—",
                                subtitle: item.first(of: "year", "ProductionYear", "sub", "episode").displayString,
                                url: session.absoluteURL(
                                    item.first(of: "poster", "image", "cover", "poster_url", "img").string))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - 原始数据

    private func rawCard(_ value: JSONValue, reload: Reload) -> some View {
        CardSection(title: "诊断", systemImage: "stethoscope") {
            VStack(alignment: .leading, spacing: 10) {
                NavigationLink {
                    JSONRawScreen(value: value["stats"], title: "dashboard_stats")
                } label: {
                    Label("dashboard_stats 原始数据", systemImage: "curlybraces")
                }
                NavigationLink {
                    JSONRawScreen(value: value["metrics"], title: "device_metrics")
                } label: {
                    Label("device_metrics 原始数据", systemImage: "curlybraces")
                }
                NavigationLink {
                    SystemHealthView()
                } label: {
                    Label("系统健康检查", systemImage: "heart.text.square")
                }
                Button {
                    reload.fire()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
            }
            .font(.subheadline)
        }
    }
}
