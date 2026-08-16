import SwiftUI

/// 系统健康：主机指标 + 网络连通性检测。
struct SystemHealthView: View {
    @EnvironmentObject private var session: AppSession
    @State private var fullTargets = false
    @State private var queryKey = 0

    var body: some View {
        RemoteScroll(title: "系统健康") {
            let api = try session.requireAPI()
            let health = await Probe.json { try await api.health.getSystemHealth(targetId: nil) }
            let network = await Probe.json { try await api.health.getLastNetworkConnectivity() }
            let targets = await Probe.json { try await api.health.getSystemHealthTargets() }
            let netTargets = await Probe.json {
                try await api.health.getNetworkConnectivityTargets(full: fullTargets ? true : nil)
            }
            return JSONValue.object(["health": health, "network": network,
                                     "targets": targets, "network_targets": netTargets])
        } content: { value, _ in
            healthCard(value["health"])
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
                    NavigationLink {
                        JSONRawScreen(value: value, title: "系统健康")
                    } label: {
                        Label("查看接口返回", systemImage: "curlybraces")
                    }
                }
                .font(.subheadline)
            }
        }
        .id(queryKey)
    }

    @ViewBuilder
    private func healthCard(_ health: JSONValue) -> some View {
        let cpu = health.deepFirst(of: "cpu_percent", "cpu", "cpu_usage")
        let memory = health.deepFirst(of: "memory_percent", "memory", "mem_percent")
        let disk = health.deepFirst(of: "disk_percent", "disk", "disk_usage")
        CardSection(title: "主机指标", systemImage: "cpu") {
            VStack(spacing: 12) {
                GaugeRow(title: "CPU", ratio: Fmt.ratio(cpu), caption: Fmt.percent(cpu, digits: 1))
                GaugeRow(title: "内存", ratio: Fmt.ratio(memory), caption: Fmt.percent(memory, digits: 1))
                GaugeRow(title: "磁盘", ratio: Fmt.ratio(disk), caption: Fmt.percent(disk, digits: 1))
                if let load = health.deepFirst(of: "load_average", "loadavg").displayString {
                    KeyValueRow("负载", load)
                }
                if let uptime = health.deepFirst(of: "uptime", "uptime_seconds").double {
                    KeyValueRow("运行时长", Fmt.duration(seconds: uptime))
                }
                if let status = health.deepFirst(of: "status", "state").displayString {
                    KeyValueRow("状态", status)
                }
            }
        }
    }

    @ViewBuilder
    private func networkCard(_ network: JSONValue) -> some View {
        let results = network.list("results", "targets", "items", "checks")
        if !results.isEmpty {
            CardSection(title: "最近一次网络检测", systemImage: "network") {
                VStack(spacing: 8) {
                    ForEach(Array(results.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text(item.first(of: "name", "target", "host").displayString ?? "—")
                                .font(.subheadline)
                            Spacer()
                            if let latency = item.deepFirst(of: "latency_ms", "latency", "elapsed_ms").double {
                                Text(String(format: "%.0f ms", latency))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            let ok = item.deepFirst(of: "ok", "success", "reachable").bool
                                ?? (item.first(of: "status").displayString == "ok")
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
                            RemoteList(title: target.first(of: "name", "id").displayString ?? "监控对象") {
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
                        let ok = item.deepFirst(of: "ok", "success", "reachable").bool ?? false
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(item.first(of: "name", "target", "host").displayString ?? "—")
                                Spacer()
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
