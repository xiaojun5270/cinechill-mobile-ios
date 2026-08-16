import Foundation
import SwiftUI
import Charts

private enum DashboardCache {
    private static let folderName = "DashboardSnapshots"

    static func load(for serverID: UUID?) -> JSONValue? {
        guard let url = fileURL(for: serverID),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(JSONValue.self, from: data)
    }

    static func save(_ value: JSONValue, for serverID: UUID?) {
        guard let url = fileURL(for: serverID),
              let data = try? JSONEncoder().encode(value) else { return }
        let folder = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: folder,
                                                 withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private static func fileURL(for serverID: UUID?) -> URL? {
        guard let serverID,
              let cacheDirectory = FileManager.default.urls(for: .cachesDirectory,
                                                              in: .userDomainMask).first else { return nil }
        return cacheDirectory
            .appendingPathComponent(folderName, isDirectory: true)
            .appendingPathComponent("\(serverID.uuidString).json")
    }
}

private func loadDashboardEmbyOverview(api: CineChillAPI) async -> JSONValue {
    guard let connection = await EmbyConnection.load(api: api) else { return .null }
    return await Probe.json {
        try await api.server.getDashboardEmbyOverview(connection)
    }
}

private struct DashboardTrendPoint: Identifiable {
    let id: String
    let label: String
    let total: Int
    let movie: Int
    let series: Int
}

private struct DashboardPanel<Content: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    var trailing: AnyView?
    @ViewBuilder var content: () -> Content

    init(title: String, systemImage: String, tint: Color, trailing: AnyView? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let trailing { trailing }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(uiColor: .separator).opacity(0.16), lineWidth: 0.5)
        }
    }
}

private struct DashboardMetric: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
    }
}

private struct DashboardGauge: View {
    let title: String
    let caption: String
    let systemImage: String
    let tint: Color
    private let ratio: Double

    init(title: String, caption: String, systemImage: String, tint: Color, ratio: Double) {
        self.title = title
        self.caption = caption
        self.systemImage = systemImage
        self.tint = tint
        self.ratio = min(max(ratio.isFinite ? ratio : 0, 0), 1)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title).font(.subheadline.weight(.medium))
                    Spacer(minLength: 8)
                    Text(caption)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                ProgressView(value: ratio)
                    .tint(ratio > 0.9 ? .red : ratio > 0.75 ? .orange : tint)
            }
        }
    }
}

private struct DashboardMetaItem: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            Text(text).lineLimit(1).minimumScaleFactor(0.75)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(tint)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

private struct DashboardActionLabel: View {
    let title: String
    let systemImage: String
    let tint: Color
    var showsChevron = true

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 8))
            Text(title).foregroundStyle(.primary)
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
    }
}

/// 仪表盘：媒体库总览、设备状态、115 账号、任务动态。
/// 服务端未声明响应结构，因此所有取值都用候选键名兜底。
struct DashboardView: View {
    @EnvironmentObject private var session: AppSession
    @State private var trendDays = 7

    var body: some View {
        let serverID = session.activeServerID
        let cachedValue = DashboardCache.load(for: serverID)

        RemoteScroll(title: "仪表盘", initialValue: cachedValue, refreshOnAppear: true) {
            let api = try session.requireAPI()
            async let statsRequest = Probe.json { try await api.server.getDashboardStats() }
            async let metricsRequest = Probe.json { try await api.server.getDashboardDeviceMetrics() }
            async let driveRequest = Probe.json { try await api.server.getDashboard115Account() }
            async let progressRequest = Probe.json { try await api.tasks.getProgress() }
            async let healthRequest = Probe.json { try await api.health.getSystemHealth() }
            async let overviewRequest = loadDashboardEmbyOverview(api: api)

            let (stats, metrics, drive, progress, health, overview) = await (
                statsRequest, metricsRequest, driveRequest,
                progressRequest, healthRequest, overviewRequest
            )
            guard !Task.isCancelled else { throw APIError.cancelled }

            let value = JSONValue.object([
                "stats": stats,
                "metrics": metrics,
                "drive115": drive,
                "progress": progress,
                "health": health,
                "overview": overview,
            ])
            DashboardCache.save(value, for: serverID)
            return value
        } content: { value, reload in
            let overview = value["overview"]
            let mediaStats = overview["media_stats"].isNull ? value["stats"] : overview["media_stats"]
            greeting
            libraryOverview(mediaStats, overview: overview)
            operationalGrid(metrics: value["metrics"], drive: value["drive115"],
                            progress: value["progress"])
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
        HStack(spacing: 14) {
            Image(systemName: salutationIcon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(salutationTint)
                .frame(width: 46, height: 46)
                .background(salutationTint.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text("\(salutation)，\(session.displayUsername)")
                    .font(.title3.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text("好内容不怕晚一点抵达，稳定才是长久的浪漫。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text(Date.now, format: .dateTime.month().day())
                    .font(.caption.weight(.semibold))
                Text(Date.now, format: .dateTime.weekday(.abbreviated))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(uiColor: .separator).opacity(0.16), lineWidth: 0.5)
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

    private var salutationIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "sun.horizon.fill"
        case 11..<18: return "sun.max.fill"
        case 18..<23: return "sunset.fill"
        default: return "moon.stars.fill"
        }
    }

    private var salutationTint: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .orange
        case 11..<18: return .blue
        case 18..<23: return .pink
        default: return .indigo
        }
    }

    @ViewBuilder
    private func operationalGrid(metrics: JSONValue, drive: JSONValue,
                                 progress: JSONValue) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 290), spacing: 12)],
                  alignment: .leading, spacing: 12) {
            deviceCard(metrics)
            drive115Card(drive)
            taskCard(progress)
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
            DashboardPanel(title: "媒体库总览", systemImage: "square.stack.3d.up", tint: .blue,
                           trailing: AnyView(StatusBadge(online ? "在线" : "离线",
                                                         tone: online ? .good : .bad))) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    DashboardMetric(title: "电影", value: countText(movies),
                                    systemImage: "film.fill", tint: .blue)
                    DashboardMetric(title: "电视剧", value: countText(series),
                                    systemImage: "tv.fill", tint: .green)
                    DashboardMetric(title: "剧集", value: countText(episodes),
                                    systemImage: "list.and.film", tint: .orange)
                    DashboardMetric(title: "用户", value: countText(users),
                                    systemImage: "person.2.fill", tint: .purple)
                }

                Divider()

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), alignment: .leading)],
                          alignment: .leading, spacing: 10) {
                    DashboardMetaItem(text: serverName, systemImage: "server.rack", tint: .green)
                    if let version = session.serverVersion {
                        let number = version.trimmingCharacters(in: .whitespacesAndNewlines)
                            .drop(while: { $0 == "v" || $0 == "V" })
                        DashboardMetaItem(text: "CineChill v\(number)",
                                          systemImage: "movieclapper.fill", tint: .blue)
                    }
                    DashboardMetaItem(text: "\(libraryCount) 个媒体库",
                                      systemImage: "cylinder", tint: .orange)
                }

                if libraryCount > 0 {
                    let ratio = min(Double(libraryCount) / Double(max(libraryLimit, 1)), 1)
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text("媒体库容量")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(libraryCount) / \(libraryLimit)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: ratio)
                            .tint(.green)
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

            DashboardPanel(title: "服务器状态", systemImage: "cpu", tint: .teal,
                           trailing: AnyView(uptimeBadge(uptime))) {
                VStack(alignment: .leading, spacing: 14) {
                    DashboardGauge(title: "CPU",
                                   caption: Fmt.percent(ratioValue(cpu), digits: 0),
                                   systemImage: "cpu", tint: .teal,
                                   ratio: Fmt.ratio(ratioValue(cpu)))
                    if let model = cpu.first(of: "model", "name", "brand").string {
                        Text(model)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .padding(.leading, 41)
                    }
                    DashboardGauge(title: "内存", caption: usedTotalText(memory),
                                   systemImage: "memorychip", tint: .blue,
                                   ratio: Fmt.ratio(ratioValue(memory)))
                    DashboardGauge(title: "硬盘", caption: usedTotalText(disk),
                                   systemImage: "internaldrive", tint: .orange,
                                   ratio: Fmt.ratio(ratioValue(disk)))

                    Divider()

                    HStack(spacing: 14) {
                        DashboardMetaItem(text: "上行 " + uploadSpeedText(network),
                                          systemImage: "arrow.up.right", tint: .orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        DashboardMetaItem(text: "下行 " + downloadSpeedText(network),
                                          systemImage: "arrow.down.left", tint: .green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
            let connectionState = drive.deepFirst(of: "connected", "is_connected", "logged_in")
            let name = drive.deepFirst(of: "account_name", "user_name", "username", "name")
                .displayString ?? "115 网盘"
            let uid = drive.deepFirst(of: "uid", "user_id").displayString ?? "--"
            let loginApp = drive.deepFirst(of: "login_app_label", "login_app", "app_name")
                .displayString
            let vipActive = drive.deepFirst(of: "vip_active", "is_vip").bool ?? false
            let vipForever = drive.deepFirst(of: "vip_forever", "is_forever_vip").bool ?? false
            let used = drive.deepFirst(of: "used_bytes", "used", "used_size", "space_used")
            let total = drive.deepFirst(of: "total_bytes", "total", "total_size", "all_total", "space_total")
            let connected = connectionState.bool ?? (used.double != nil || total.double != nil)
            let vip = drive.deepFirst(of: "vip_label", "vip_name", "vip")
                .displayString ?? (connected ? "已连接" : "未连接")
            let remain = drive.deepFirst(of: "remain_bytes", "remaining", "remain", "space_remain")
            let usage = drive.deepFirst(of: "usage_percent", "used_percent", "percentage", "ratio")
            let usedText = drive.deepFirst(of: "used_human", "used_text").displayString ?? Fmt.bytes(used)
            let totalText = drive.deepFirst(of: "total_human", "total_text").displayString ?? Fmt.bytes(total)
            let remainText = drive.deepFirst(of: "remain_human", "remaining_human", "remain_text")
                .displayString ?? Fmt.bytes(remain)
            let message = drive.deepFirst(of: "message", "detail", "error").displayString
                ?? "115 账号未连接"
            let expireAt = drive.deepFirst(of: "vip_expire_at", "vip_expire", "expire_at")
            let ratio = usage.double != nil
                ? Fmt.ratio(usage)
                : ((total.double ?? 0) > 0 ? (used.double ?? 0) / (total.double ?? 1) : 0)
            let vipTone: BadgeTone = connected
                ? ((vipActive || vipForever) ? .good : .info)
                : .bad

            DashboardPanel(title: "115 网盘", systemImage: "externaldrive.badge.icloud", tint: .green,
                           trailing: AnyView(StatusBadge(vip, tone: vipTone))) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 11) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(connected ? Color.green : Color.gray)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(name)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            HStack(spacing: 5) {
                                Text("UID \(uid)")
                                if let loginApp, !loginApp.isEmpty {
                                    Text("·")
                                    Text(loginApp)
                                        .lineLimit(1)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }

                    if connected {
                        DashboardGauge(title: "存储空间",
                                       caption: "\(usedText) / \(totalText)",
                                       systemImage: "externaldrive.fill", tint: .green,
                                       ratio: ratio)

                        HStack(spacing: 12) {
                            Label("剩余 \(remainText)", systemImage: "internaldrive")
                            Spacer(minLength: 8)
                            Text(Fmt.percent(usage.double ?? ratio, digits: 1))
                                .monospacedDigit()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if !vipForever, !expireAt.isNull {
                            Label("会员到期 \(Fmt.fullDateTime(expireAt))", systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Label(message, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    // MARK: - 任务动态

    @ViewBuilder
    private func taskCard(_ progress: JSONValue) -> some View {
        let running = TaskWatch.items(from: progress).filter { !$0.isFinished }
        DashboardPanel(title: "任务动态", systemImage: "bolt.horizontal.fill", tint: .orange,
                       trailing: AnyView(StatusBadge(running.isEmpty ? "空闲" : "\(running.count) 项运行中",
                                                     tone: running.isEmpty ? .neutral : .good))) {
            VStack(alignment: .leading, spacing: 12) {
                if running.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("当前没有运行中的任务")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(Array(running.prefix(5).enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "bolt.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                                .frame(width: 28, height: 28)
                                .background(Color.orange.opacity(0.11),
                                            in: RoundedRectangle(cornerRadius: 7))
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(item.name)
                                        .font(.subheadline.weight(.medium))
                                        .lineLimit(1)
                                    Spacer(minLength: 8)
                                    StatusBadge(item.status.isEmpty ? "运行中" : item.status,
                                                tone: item.status.isEmpty ? .good : badgeTone(for: item.status))
                                }
                                if let percent = item.percent {
                                    HStack(spacing: 8) {
                                        ProgressView(value: Fmt.ratio(.double(percent)))
                                            .tint(.orange)
                                        Text(Fmt.percent(.double(percent), digits: 0))
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Divider()

                NavigationLink {
                    TaskCenterView()
                } label: {
                    DashboardActionLabel(title: "任务中心",
                                         systemImage: "list.bullet.rectangle", tint: .orange)
                }
            }
        }
    }

    // MARK: - 入库趋势

    @ViewBuilder
    private func trendCard(_ overview: JSONValue) -> some View {
        let points = trendPoints(overview, days: trendDays)
        if !points.isEmpty {
            DashboardPanel(title: "入库趋势", systemImage: "chart.xyaxis.line", tint: .indigo,
                           trailing: AnyView(
                               Picker("趋势周期", selection: $trendDays) {
                                   Text("7天").tag(7)
                                   Text("30天").tag(30)
                               }
                               .pickerStyle(.segmented)
                               .frame(width: 126)
                           )) {
                let total = points.reduce(0) { $0 + $1.total }
                let movies = points.reduce(0) { $0 + $1.movie }
                let series = points.reduce(0) { $0 + $1.series }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    DashboardMetric(title: "全部", value: String(total),
                                    systemImage: "checklist", tint: .indigo)
                    DashboardMetric(title: "电影", value: String(movies),
                                    systemImage: "film.fill", tint: .blue)
                    DashboardMetric(title: "剧集", value: String(series),
                                    systemImage: "square.stack.3d.up.fill", tint: .orange)
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
            DashboardPanel(title: "继续观看", systemImage: "play.circle.fill", tint: .blue,
                           trailing: AnyView(StatusBadge("\(playbacks.count) 部", tone: .info))) {
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
            DashboardPanel(title: "媒体库", systemImage: "rectangle.stack.fill", tint: .cyan,
                           trailing: AnyView(StatusBadge("\(libraries.count) 个", tone: .info))) {
                VStack(spacing: 0) {
                    ForEach(Array(libraries.prefix(20).enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 11) {
                            let tint = libraryTint(item)
                            Image(systemName: libraryIcon(item))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(tint)
                                .frame(width: 30, height: 30)
                                .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 8))
                            Text(item.first(of: "name", "Name", "title").displayString
                                 ?? item.displayString ?? "—")
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            Spacer()
                            let count = item.first(of: "count", "total", "item_count", "ItemCount")
                            if !count.isNull {
                                Text(countText(count) + " 部")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 7)
                        if index < min(libraries.count, 20) - 1 {
                            Divider().padding(.leading, 41)
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
            DashboardPanel(title: "最近入库", systemImage: "clock.arrow.circlepath", tint: .orange,
                           trailing: AnyView(StatusBadge("\(recent.count) 部", tone: .warning))) {
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

    private func libraryTint(_ item: JSONValue) -> Color {
        switch item.first(of: "type", "collection_type", "CollectionType").displayString?.lowercased() {
        case "movie", "movies": return .blue
        case "series", "tv", "tvshows": return .green
        default: return .orange
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
        return DashboardPanel(title: "诊断", systemImage: "stethoscope", tint: .red,
                              trailing: AnyView(
                                  StatusBadge("\(available)/\(snapshots.count) 可用",
                                              tone: available == snapshots.count ? .good : .warning))) {
            VStack(alignment: .leading, spacing: 0) {
                NavigationLink {
                    DashboardEndpointDiagnosticsView()
                } label: {
                    DashboardActionLabel(title: "运行完整接口诊断",
                                         systemImage: "waveform.path.ecg", tint: .red)
                }
                .padding(.vertical, 6)
                Divider().padding(.leading, 41)
                NavigationLink {
                    SystemHealthView()
                } label: {
                    DashboardActionLabel(title: "系统健康检查",
                                         systemImage: "heart.text.square.fill", tint: .pink)
                }
                .padding(.vertical, 6)
                Divider().padding(.leading, 41)
                NavigationLink {
                    SystemLogsView()
                } label: {
                    DashboardActionLabel(title: "系统日志",
                                         systemImage: "doc.text.fill", tint: .blue)
                }
                .padding(.vertical, 6)
                Divider().padding(.leading, 41)
                Button {
                    reload.fire()
                } label: {
                    DashboardActionLabel(title: "刷新仪表盘数据",
                                         systemImage: "arrow.clockwise", tint: .green,
                                         showsChevron: false)
                }
                .padding(.vertical, 6)
            }
        }
    }

}
