import SwiftUI

/// 系统健康：主机指标 + 网络连通性检测。
struct SystemHealthView: View {
    @EnvironmentObject private var session: AppSession
    @State private var fullTargets = false
    @State private var queryKey = 0

    var body: some View {
        RemoteScroll(title: "系统健康") {
            let api = try session.requireAPI()
            let metrics = await Probe.json { try await api.server.getDashboardDeviceMetrics() }
            let health = await Probe.json { try await api.health.getSystemHealth(targetId: nil) }
            let network = await Probe.json { try await api.health.getLastNetworkConnectivity() }
            let targets = await Probe.json { try await api.health.getSystemHealthTargets() }
            let netTargets = await Probe.json {
                try await api.health.getNetworkConnectivityTargets(full: fullTargets ? true : nil)
            }
            return JSONValue.object(["metrics": metrics, "health": health, "network": network,
                                     "targets": targets, "network_targets": netTargets])
        } content: { value, _ in
            metricsCard(value["metrics"])
            healthChecksCard(value["health"])
            networkCard(value["network"])
            targetsCard(value["targets"])
            connectivityTargetsCard(value["network_targets"])
            CardSection(title: "更多", systemImage: "ellipsis.circle") {
                VStack(alignment: .leading, spacing: 10) {
                    NavigationLink {
                        NetworkCheckView()
                    } label: {
                        Label("立即检测网络连通性", systemImage: "wifi.exclamationmark")
                    }
                }
                .font(.subheadline)
            }
        }
        .id(queryKey)
    }

    @ViewBuilder
    private func metricsCard(_ metrics: JSONValue) -> some View {
        let cpu = metrics.deepFirst(of: "cpu", "cpu_usage", "cpu_percent", "cpuUsage")
        let memory = metrics.deepFirst(of: "memory", "mem", "ram", "memory_usage", "memory_percent")
        let disk = metrics.deepFirst(of: "disk", "storage", "disk_usage", "disk_percent")
        let uptime = metrics.deepFirst(of: "uptime", "uptime_seconds", "boot_seconds")
        let hasMetrics = !cpu.isNull || !memory.isNull || !disk.isNull

        CardSection(title: "主机指标", systemImage: "cpu") {
            if hasMetrics {
                VStack(spacing: 12) {
                    GaugeRow(title: "CPU",
                             ratio: Fmt.ratio(ratioValue(cpu)),
                             caption: Fmt.percent(ratioValue(cpu), digits: 1))
                    GaugeRow(title: "内存",
                             ratio: Fmt.ratio(ratioValue(memory)),
                             caption: usedTotalText(memory))
                    GaugeRow(title: "磁盘",
                             ratio: Fmt.ratio(ratioValue(disk)),
                             caption: usedTotalText(disk))
                    if let seconds = uptime.first(of: "seconds", "value", "total_seconds").double
                        ?? uptime.double {
                        KeyValueRow("运行时长", Fmt.duration(seconds: seconds))
                    } else if let text = uptime.first(of: "text", "human", "display", "formatted").displayString
                        ?? uptime.displayString {
                        KeyValueRow("运行时长", text)
                    }
                }
            } else {
                Text("设备指标接口未返回 CPU、内存或磁盘数据")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func healthChecksCard(_ health: JSONValue) -> some View {
        let items = health.list("items", "checks", "results")
        let overall = healthTone(health.first(of: "status", "state").displayString)
        let total = health.path("summary", "total").int ?? items.count
        let ok = health.path("summary", "ok").int
            ?? items.filter { $0.first(of: "status", "state").displayString?.lowercased() == "ok" }.count

        CardSection(title: "系统检查项", systemImage: "checkmark.shield",
                    trailing: AnyView(StatusBadge(overall.label, tone: overall.tone))) {
            VStack(alignment: .leading, spacing: 10) {
                if total > 0 {
                    KeyValueRow("检查结果", "\(ok) / \(total) 正常")
                }
                if let checkedAt = health.first(of: "checked_at", "updated_at", "time").displayString {
                    let elapsed = health.first(of: "elapsed_ms", "duration_ms").int
                    KeyValueRow("检查时间", elapsed.map { "\(checkedAt) · \($0) ms" } ?? checkedAt)
                }

                if items.isEmpty {
                    Text(health.errorMessage ?? "服务端没有返回系统健康检查项")
                        .font(.footnote)
                        .foregroundStyle(overall.isError ? Color.red : Color.secondary)
                } else {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        healthCheckRow(item)
                        if index < items.count - 1 { Divider() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func healthCheckRow(_ item: JSONValue) -> some View {
        let status = healthTone(item.first(of: "status", "state").displayString)
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(item.first(of: "label", "name", "id").displayString ?? "健康检查项")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                StatusBadge(status.label, tone: status.tone)
            }
            if let message = item.first(of: "message", "summary").displayString, !message.isEmpty {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let detail = item.first(of: "detail", "error", "reason").displayString, !detail.isEmpty {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(status.isError ? Color.red : Color.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    private func healthTone(_ rawValue: String?) -> (label: String, tone: BadgeTone, isError: Bool) {
        switch rawValue?.lowercased() {
        case "ok", "success", "healthy": return ("正常", .good, false)
        case "warning", "warn": return ("警告", .warning, false)
        case "error", "failed", "unhealthy": return ("异常", .bad, true)
        case "disabled": return ("未启用", .neutral, false)
        case "checking": return ("检查中", .info, false)
        default: return ("未知", .neutral, false)
        }
    }

    private func ratioValue(_ node: JSONValue) -> JSONValue {
        guard node.object != nil else { return node }
        return node.first(of: "percent", "percentage", "usage", "used_percent", "usage_percent",
                             "ratio", "load", "value")
    }

    private func usedTotalText(_ node: JSONValue) -> String {
        if let text = node.first(of: "text", "summary").string, !text.isEmpty { return text }
        let used = node.first(of: "used", "used_bytes", "used_gb")
        let total = node.first(of: "total", "total_bytes", "total_gb", "size")
        guard used.double != nil || total.double != nil else {
            return Fmt.percent(ratioValue(node), digits: 1)
        }
        let scale: Double = node["used_gb"].double == nil ? 1 : 1024 * 1024 * 1024
        return "\(Fmt.bytes(used.double.map { $0 * scale })) / \(Fmt.bytes(total.double.map { $0 * scale }))"
    }

    @ViewBuilder
    private func networkCard(_ network: JSONValue) -> some View {
        let results = network.list("results", "targets", "items", "checks")
        if !results.isEmpty {
            CardSection(title: "最近一次网络检测", systemImage: "network") {
                VStack(spacing: 8) {
                    ForEach(Array(results.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text(item.first(of: "label", "name", "target", "host", "url").displayString ?? "—")
                                .font(.subheadline)
                            Spacer()
                            if let latency = item.deepFirst(of: "latency_ms", "latency", "elapsed_ms").double {
                                Text(String(format: "%.0f ms", latency))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            let state = item.first(of: "status", "state").displayString?.lowercased()
                            let ok = item.deepFirst(of: "ok", "success", "reachable").bool
                                ?? (state == "ok" || state == "success")
                            StatusBadge(ok ? "通畅" : "失败", tone: ok ? .good : .bad)
                        }
                    }
                    if let time = network.deepFirst(of: "checked_at", "updated_at", "time").displayString {
                        KeyValueRow("检测时间", Fmt.relative(.string(time)))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func targetsCard(_ targets: JSONValue) -> some View {
        let list = targets.list("targets", "items")
        if !list.isEmpty {
            CardSection(title: "监控对象", systemImage: "scope") {
                VStack(spacing: 6) {
                    ForEach(Array(list.enumerated()), id: \.offset) { _, target in
                        NavigationLink {
                            RemoteList(title: target.first(of: "label", "name", "id").displayString ?? "监控对象") {
                                let api = try session.requireAPI()
                                let id = target.first(of: "id", "target_id").displayString
                                return try await api.health.getSystemHealth(targetId: id)
                            } content: { value, _ in
                                Section { JSONFieldList(value: value) }
                            }
                        } label: {
                            HStack {
                                Text(target.first(of: "name", "label", "id").displayString ?? "—")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private func connectivityTargetsCard(_ targets: JSONValue) -> some View {
        let list = targets.list("targets", "items", "data")
        CardSection(title: "连通性目标", systemImage: "antenna.radiowaves.left.and.right") {
            VStack(alignment: .leading, spacing: 8) {
                if list.isEmpty {
                    Text("服务端没有返回连通性目标")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(list.enumerated()), id: \.offset) { _, target in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(target.first(of: "name", "label", "host", "url").displayString ?? "—")
                                    .font(.subheadline)
                                if let address = target.first(of: "url", "host", "address").displayString {
                                    Text(address)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            if let enabled = target.first(of: "enabled", "active").bool {
                                StatusBadge(enabled ? "启用" : "停用", tone: enabled ? .good : .neutral)
                            }
                        }
                    }
                }

                Toggle("显示全部检测目标", isOn: $fullTargets)
                    .font(.subheadline)
                    .onChange(of: fullTargets) { _, _ in queryKey += 1 }
            }
        }
    }
}

/// 主动发起一次网络连通性检测（full=true 会检测全部目标，耗时较长）。
struct NetworkCheckView: View {
    @EnvironmentObject private var session: AppSession
    @State private var full = false
    @State private var queryKey = 0

    var body: some View {
        RemoteList(title: "网络连通性") {
            let api = try session.requireAPI()
            return try await api.health.getNetworkConnectivity(targetId: nil, full: full)
        } content: { value, _ in
            Section("选项") {
                Toggle("完整检测（较慢）", isOn: $full)
                    .onChange(of: full) { _, _ in queryKey += 1 }
            }
            let results = value.list("results", "targets", "checks", "items")
            if results.isEmpty {
                Section { JSONFieldList(value: value) }
            } else {
                Section("结果") {
                    ForEach(Array(results.enumerated()), id: \.offset) { _, item in
                        let rawStatus = item.first(of: "status", "state").displayString?.lowercased()
                        let ok = item.deepFirst(of: "ok", "success", "reachable").bool
                            ?? (rawStatus == "ok" || rawStatus == "success")
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(item.first(of: "label", "name", "target", "host", "url").displayString ?? "—")
                                Spacer()
                                if let latency = item.first(of: "latency_ms", "latency", "elapsed_ms").double {
                                    Text(String(format: "%.0f ms", latency))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                StatusBadge(ok ? "通畅" : "失败", tone: ok ? .good : .bad)
                            }
                            if let detail = item.first(of: "message", "error", "detail").displayString {
                                Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(3)
                            }
                        }
                    }
                }
            }
        }
        .id(queryKey)
    }
}
