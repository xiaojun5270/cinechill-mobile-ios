import SwiftUI
import Charts

private struct DashboardTrendPoint: Identifiable {
    let id: String
    let label: String
    let total: Int
    let movie: Int
    let series: Int
}

/// 仪表盘：媒体库总览、设备状态、115 账号、任务动态。
/// 服务端未声明响应结构，因此所有取值都用候选键名兜底。
struct DashboardView: View {
    @EnvironmentObject private var session: AppSession
    @State private var trendDays = 7

    var body: some View {
        RemoteScroll(title: "仪表盘") {
            let api = try session.requireAPI()
            let stats = await Probe.json { try await api.server.getDashboardStats() }
            let metrics = await Probe.json { try await api.server.getDashboardDeviceMetrics() }
            let drive = await Probe.json { try await api.server.getDashboard115Account() }
            let progress = await Probe.json { try await api.tasks.getProgress() }
            let health = await Probe.json { try await api.health.getSystemHealth() }
            let overview: JSONValue
            if let connection = await EmbyConnection.load(api: api) {
                overview = await Probe.json {
                    try await api.server.getDashboardEmbyOverview(connection)
                }
            } else {
                overview = .null
            }
            return JSONValue.object([
                "stats": stats,
                "metrics": metrics,
                "drive115": drive,
                "progress": progress,
                "health": health,
                "overview": overview,
            ])
        } content: { value, reload in
            greeting
            let overview = value["overview"]
            let mediaStats = overview["media_stats"].isNull ? value["stats"] : overview["media_stats"]
            libraryOverview(mediaStats, overview: overview)
            deviceCard(value["metrics"])
            drive115Card(value["drive115"])
            taskCard(value["progress"])
            trendCard(overview)
            continueWatchingCard(overview)
            librariesCard(mediaStats)
            recentCard(overview)
            diagnosticCard(value, reload: reload)
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
        VStack(alignment: .leading, spacing: 6) {
            Text("\(salutation)，\(session.displayUsername)")
                .font(.title3.weight(.semibold))
            Text("好内容不怕晚一点抵达，稳定才是长久的浪漫。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
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
    private func libraryOverview(_ stats: JSONValue, overview: JSONValue) -> some View {
        let movies = stats.deepFirst(of: "movie_count", "movies", "MovieCount", "total_movies")
        let series = stats.deepFirst(of: "series_count", "series", "SeriesCount", "tv_count", "shows")
        let episodes = stats.deepFirst(of: "episode_count", "episodes", "EpisodeCount", "total")
        let users = stats.deepFirst(of: "user_count", "users_count", "users", "UserCount")
        let libraries = stats.list("libraries", "views", "library_list")
        let classifiedLibraryCount = (stats["movie_libraries"].int ?? 0)
            + (stats["series_libraries"].int ?? 0)
            + (stats["other_libraries"].int ?? 0)
        let libraryCount = libraries.count > 0
            ? libraries.count
            : stats.first(of: "library_count", "libraries").int ?? classifiedLibraryCount
        let libraryLimit = overview.first(of: "library_limit", "max_libraries").int ?? 128
        let online = overview.deepFirst(of: "online", "connected", "available").bool ?? true
        let serverName = overview.first(of: "server_name", "serverName", "name").displayString ?? "Emby Server"

        if !stats.isNull {
            CardSection(title: "媒体库总览", systemImage: "square.stack.3d.up",
                        trailing: AnyView(StatusBadge(online ? "\(serverName) 在线" : "\(serverName) 离线",
                                                      tone: online ? .good : .bad))) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MetricTile(title: "电影", value: countText(movies), systemImage: "film", tone: .info)
                    MetricTile(title: "电视剧", value: countText(series), systemImage: "tv", tone: .good)
                    MetricTile(title: "剧集", value: countText(episodes), systemImage: "list.and.film", tone: .warning)
                    MetricTile(title: "用户", value: countText(users), systemImage: "person.2", tone: .neutral)
                }
                HStack(spacing: 12) {
                    Label("Emby Server", systemImage: "server.rack")
                    if let version = session.serverVersion {
                        let number = version.trimmingCharacters(in: .whitespacesAndNewlines)
                            .drop(while: { $0 == "v" || $0 == "V" })
                        Label("CineChill v\(number)", systemImage: "movieclapper")
                    }
                    Label("\(libraryCount) 个媒体库", systemImage: "cylinder")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                if libraryCount > 0 {
                    HStack(spacing: 8) {
                        Text(Fmt.percent(Double(libraryCount) / Double(max(libraryLimit, 1))))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.green)
                        ProgressView(value: min(Double(libraryCount) / Double(max(libraryLimit, 1)), 1))
                            .tint(.green)
                        Text("\(libraryCount) / \(libraryLimit)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
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
            let cpu = metrics.deepFirst(of: "cpu", "cpu_usage", "cpu_percent", "cpuUsage")
            let memory = metrics.deepFirst(of: "memory", "mem", "ram", "memory_usage", "memory_percent")
            let disk = metrics.deepFirst(of: "disk", "storage", "disk_usage", "disk_percent")
            let networkNode = metrics.deepFirst(of: "network", "net", "network_io")
            let network = networkNode.isNull ? metrics : networkNode
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
                        Label("上行 " + uploadSpeedText(network),
                              systemImage: "arrow.up")
                        Spacer()
                        Label("下行 " + downloadSpeedText(network),
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
            if let text = uptime.first(of: "text", "human", "display", "formatted").displayString,
               !text.isEmpty {
                StatusBadge("运行 " + text, tone: .good)
            } else if let seconds = uptime.first(of: "seconds", "value", "total_seconds").double,
                      seconds > 0 {
                StatusBadge("运行 " + Fmt.duration(seconds: seconds), tone: .good)
            } else if let seconds = uptime.double, seconds > 0 {
                StatusBadge("运行 " + Fmt.duration(seconds: seconds), tone: .good)
            } else if let text = uptime.string, !text.isEmpty {
                StatusBadge(text, tone: .good)
            }
        }
    }

    /// 兼容 `{percent: 66}`、`{usage: 0.66}` 与直接给数字两种形态。
    private func ratioValue(_ node: JSONValue) -> JSONValue {
        if node.object != nil {
            return node.first(of: "percent", "percentage", "usage", "used_percent", "usage_percent",
                              "ratio", "load", "value")
        }
        return node
    }

    private func uploadSpeedText(_ network: JSONValue) -> String {
        if let text = network.first(of: "up_human", "upload_human", "tx_human").displayString,
           !text.isEmpty { return text }
        return Fmt.speed(network.first(of: "upload", "up", "tx", "sent", "upload_bytes"))
    }

    private func downloadSpeedText(_ network: JSONValue) -> String {
        if let text = network.first(of: "down_human", "download_human", "rx_human").displayString,
           !text.isEmpty { return text }
        return Fmt.speed(network.first(of: "download", "down", "rx", "recv", "download_bytes"))
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
                }
            }
        }
    }

    // MARK: - 任务动态

    @ViewBuilder
    private func taskCard(_ progress: JSONValue) -> some View {
        let running = TaskWatch.items(from: progress).filter { !$0.isFinished }
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
                                Text(item.name)
                                    .font(.subheadline)
                                Spacer()
                                StatusBadge(item.status.isEmpty ? "运行中" : item.status,
                                            tone: item.status.isEmpty ? .good : badgeTone(for: item.status))
                            }
                            if let percent = item.percent {
                                ProgressView(value: Fmt.ratio(.double(percent)))
                                Text(Fmt.percent(.double(percent), digits: 0))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
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

    // MARK: - 入库趋势

    @ViewBuilder
    private func trendCard(_ overview: JSONValue) -> some View {
        let points = trendPoints(overview, days: trendDays)
        if !points.isEmpty {
            CardSection(title: "入库趋势", systemImage: "chart.xyaxis.line",
                        trailing: AnyView(
                            Picker("趋势周期", selection: $trendDays) {
                                Text("7天").tag(7)
                                Text("30天").tag(30)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 130)
                        )) {
                let total = points.reduce(0) { $0 + $1.total }
                let movies = points.reduce(0) { $0 + $1.movie }
                let series = points.reduce(0) { $0 + $1.series }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    MetricTile(title: "全部", value: String(total), systemImage: "checklist", tone: .info)
                    MetricTile(title: "电影", value: String(movies), systemImage: "film", tone: .good)
                    MetricTile(title: "剧集", value: String(series), systemImage: "square.stack.3d.up", tone: .warning)
                }
                Chart(points) { point in
                    AreaMark(
                        x: .value("日期", point.label),
                        y: .value("入库", point.total)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.accentColor.opacity(0.12))

                    LineMark(
                        x: .value("日期", point.label),
                        y: .value("入库", point.total)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.accentColor)
                    .symbol(Circle())
                }
                .frame(height: 150)
                .chartYScale(domain: 0...max(points.map(\.total).max() ?? 0, 1))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(points.count, 7)))
                }
            }
        }
    }

    private func trendPoints(_ overview: JSONValue, days: Int) -> [DashboardTrendPoint] {
        let rows = overview.deepFirst(of: "ingest_trend", "ingestTrend", "trend").array ?? []
        let points = rows.enumerated().map { index, row in
            let key = row.first(of: "date", "key", "day").displayString ?? String(index + 1)
            let movie = row.first(of: "movie", "movie_count", "movieCount").int ?? 0
            let series = row.first(of: "series", "series_count", "seriesCount").int ?? 0
            let total = row.first(of: "total", "count", "all").int ?? movie + series
            return DashboardTrendPoint(id: "\(key)-\(index)", label: trendLabel(key),
                                       total: total, movie: movie, series: series)
        }
        return Array(points.suffix(max(days, 1)))
    }

    private func trendLabel(_ raw: String) -> String {
        let parts = raw.split(separator: "-")
        guard parts.count >= 3,
              let month = Int(parts[parts.count - 2]),
              let day = Int(parts[parts.count - 1].prefix(2)) else { return raw }
        return "\(month)/\(day)"
    }

    // MARK: - 继续观看

    @ViewBuilder
    private func continueWatchingCard(_ overview: JSONValue) -> some View {
        let playbacks = overview.deepFirst(of: "recent_playbacks", "recentPlaybacks",
                                           "continue_watching", "continueWatching").array ?? []
        if !playbacks.isEmpty {
            CardSection(title: "继续观看", systemImage: "play.circle") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(playbacks.prefix(20).enumerated()), id: \.offset) { _, item in
                            playbackLink(item)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    private func playbackLink(_ item: JSONValue) -> some View {
        if let destination = mediaWebURL(item) {
            Link(destination: destination) { playbackCard(item) }
                .buttonStyle(.plain)
        } else {
            playbackCard(item)
        }
    }

    private func playbackCard(_ item: JSONValue) -> some View {
        let width: CGFloat = 220
        let ratio = playbackRatio(item)
        return VStack(alignment: .leading, spacing: 6) {
            RemoteImage(url: Artwork.backdropURL(for: item, api: session.api, session: session),
                        placeholderIcon: "play.rectangle")
                .frame(width: width, height: 124)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .bottom) {
                    ProgressView(value: ratio)
                        .tint(.green)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 6)
                }
            HStack(spacing: 6) {
                Text(mediaTitle(item))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(Fmt.percent(ratio, digits: 0))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: width)
            if let subtitle = mediaSubtitle(item) {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: width, alignment: .leading)
            }
        }
    }

    private func playbackRatio(_ item: JSONValue) -> Double {
        let percent = item.first(of: "progress_percent", "played_percentage", "played_percent",
                                 "playedPercentage", "progress", "percent")
        if let value = percent.double { return Fmt.ratio(.double(value)) }
        let position = item.first(of: "playback_position_ticks", "playbackPositionTicks",
                                  "position_ticks", "positionTicks").double
        let runtime = item.first(of: "runtime_ticks", "runtimeTicks", "run_time_ticks").double
        guard let position, let runtime, runtime > 0 else { return 0 }
        return min(max(position / runtime, 0), 1)
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
                            Label(item.first(of: "name", "Name", "title").displayString
                                  ?? item.displayString ?? "—",
                                  systemImage: libraryIcon(item))
                                .font(.subheadline)
                            Spacer()
                            let count = item.first(of: "count", "total", "item_count", "ItemCount")
                            if !count.isNull {
                                Text(countText(count) + " 部")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 最近入库

    @ViewBuilder
    private func recentCard(_ overview: JSONValue) -> some View {
        let recent = overview.deepFirst(of: "recent_items", "recentItems", "recently_added",
                                        "recentlyAdded", "latest", "recent").array ?? []
        if !recent.isEmpty {
            CardSection(title: "最近入库", systemImage: "clock.arrow.circlepath") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(recent.prefix(24).enumerated()), id: \.offset) { _, item in
                            recentItemLink(item)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    private func recentItemLink(_ item: JSONValue) -> some View {
        let poster = PosterCard(title: mediaTitle(item), subtitle: mediaSubtitle(item),
                                badge: mediaTypeLabel(item),
                                url: Artwork.url(for: item, api: session.api, session: session))
        if let destination = mediaWebURL(item) {
            Link(destination: destination) { poster }
                .buttonStyle(.plain)
        } else {
            poster
        }
    }

    private func mediaTitle(_ item: JSONValue) -> String {
        item.first(of: "title", "name", "Name", "series_name", "seriesName").displayString ?? "—"
    }

    private func mediaSubtitle(_ item: JSONValue) -> String? {
        var values: [String] = []
        if let year = item.first(of: "year", "ProductionYear", "production_year").displayString,
           !year.isEmpty { values.append(year) }
        if let label = item.first(of: "episode_label", "episodeLabel", "sub").displayString,
           !label.isEmpty {
            values.append(label)
        } else {
            let season = item.first(of: "season", "season_number", "seasonNumber").int
            let episode = item.first(of: "episode", "episode_number", "episodeNumber").int
            if let season, let episode {
                values.append(String(format: "S%02dE%02d", season, episode))
            } else if let episode {
                values.append("第 \(episode) 集")
            }
        }
        return values.isEmpty ? nil : values.joined(separator: " · ")
    }

    private func mediaTypeLabel(_ item: JSONValue) -> String? {
        guard let type = item.first(of: "media_type", "mediaType", "type", "Type").displayString else {
            return nil
        }
        switch type.lowercased() {
        case "movie": return "电影"
        case "series", "tv", "show": return "电视剧"
        case "episode": return "剧集"
        default: return type
        }
    }

    private func libraryIcon(_ item: JSONValue) -> String {
        switch item.first(of: "type", "collection_type", "CollectionType").displayString?.lowercased() {
        case "movie", "movies": return "film"
        case "series", "tv", "tvshows": return "tv"
        default: return "rectangle.stack"
        }
    }

    private func mediaWebURL(_ item: JSONValue) -> URL? {
        guard let raw = item.first(of: "web_url", "webUrl", "url", "href").displayString,
              !raw.isEmpty else { return nil }
        if raw.hasPrefix("/") { return session.absoluteURL(raw) }
        return URL(string: raw)
    }

    // MARK: - 诊断

    private func diagnosticCard(_ value: JSONValue, reload: Reload) -> some View {
        let snapshots = [value["stats"], value["metrics"], value["drive115"],
                         value["overview"], value["progress"], value["health"]]
        let available = snapshots.filter { !$0.isNull && !$0.isEmptyContainer }.count
        return CardSection(title: "诊断", systemImage: "stethoscope",
                           trailing: AnyView(
                            StatusBadge("\(available)/\(snapshots.count) 可用",
                                        tone: available == snapshots.count ? .good : .warning)
            )) {
            VStack(alignment: .leading, spacing: 10) {
                NavigationLink {
                    DashboardEndpointDiagnosticsView()
                } label: {
                    Label("运行完整接口诊断", systemImage: "waveform.path.ecg")
                }
                NavigationLink {
                    SystemHealthView()
                } label: {
                    Label("系统健康检查", systemImage: "heart.text.square")
                }
                NavigationLink {
                    SystemLogsView()
                } label: {
                    Label("系统日志", systemImage: "doc.plaintext")
                }
                Button {
                    reload.fire()
                } label: {
                    Label("刷新仪表盘数据", systemImage: "arrow.clockwise")
                }
            }
            .font(.subheadline)
        }
    }

}
