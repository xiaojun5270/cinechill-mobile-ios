import SwiftUI

/// 对仪表盘依赖的接口逐一发起请求，保留错误信息与耗时，避免 `Probe` 的静默降级掩盖故障。
struct DashboardEndpointDiagnosticsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteScroll(title: "接口诊断") {
            let api = try session.requireAPI()
            var checks: [JSONValue] = []
            checks.append(await check("仪表盘统计", endpoint: "GET /api/dashboard_stats") {
                try await api.server.getDashboardStats()
            })
            checks.append(await check("设备指标", endpoint: "GET /api/dashboard_device_metrics") {
                try await api.server.getDashboardDeviceMetrics()
            })
            checks.append(await check("115 账号", endpoint: "GET /api/dashboard_115_account") {
                try await api.server.getDashboard115Account()
            })
            checks.append(await check("任务进度", endpoint: "GET /api/progress") {
                try await api.tasks.getProgress()
            })
            checks.append(await check("系统健康", endpoint: "GET /api/system_health") {
                try await api.health.getSystemHealth()
            })
            if let connection = await EmbyConnection.load(api: api) {
                checks.append(await check("Emby 总览", endpoint: "POST /api/dashboard_emby_overview") {
                    try await api.server.getDashboardEmbyOverview(connection)
                })
            } else {
                checks.append(failedCheck("Emby 总览", endpoint: "POST /api/dashboard_emby_overview",
                                          message: "未能从 config_302 或旧版配置读取 Emby 地址与 API Key"))
            }
            return .object(["checks": .array(checks)])
        } content: { value, reload in
            let checks = value["checks"].array ?? []
            summaryCard(checks)
            ForEach(Array(checks.enumerated()), id: \.offset) { _, item in
                resultCard(item)
            }
            CardSection(title: "工具", systemImage: "wrench.and.screwdriver") {
                NavigationLink {
                    SystemHealthView()
                } label: {
                    Label("系统健康与网络检测", systemImage: "heart.text.square")
                }
                Button {
                    reload.fire()
                } label: {
                    Label("重新运行全部诊断", systemImage: "arrow.clockwise")
                }
            }
            .font(.subheadline)
        }
    }

    private func summaryCard(_ checks: [JSONValue]) -> some View {
        let passed = checks.filter { $0["ok"].bool == true }.count
        let failed = checks.count - passed
        return CardSection(title: "诊断结果", systemImage: "checkmark.shield",
                           trailing: AnyView(
                            StatusBadge(failed == 0 ? "全部正常" : "\(failed) 项异常",
                                        tone: failed == 0 ? .good : .bad)
                           )) {
            HStack(spacing: 10) {
                MetricTile(title: "已检测", value: String(checks.count),
                           systemImage: "stethoscope", tone: .info)
                MetricTile(title: "正常", value: String(passed),
                           systemImage: "checkmark.circle", tone: .good)
                MetricTile(title: "异常", value: String(failed),
                           systemImage: "exclamationmark.triangle", tone: failed == 0 ? .neutral : .bad)
            }
        }
    }

    private func resultCard(_ item: JSONValue) -> some View {
        let ok = item["ok"].bool == true
        let empty = item["empty"].bool == true
        let status = empty ? "空响应" : (ok ? "正常" : "失败")
        let tone: BadgeTone = empty ? .warning : (ok ? .good : .bad)
        return CardSection(title: item["name"].displayString ?? "接口",
                           systemImage: empty ? "exclamationmark.triangle"
                            : (ok ? "checkmark.circle" : "xmark.octagon"),
                           trailing: AnyView(StatusBadge(status, tone: tone))) {
            if let endpoint = item["endpoint"].displayString {
                Text(endpoint)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            if let elapsed = item["elapsed_ms"].int {
                KeyValueRow("响应耗时", "\(elapsed) ms", monospaced: true)
            }
            if let error = item["error"].displayString, !error.isEmpty {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
            NavigationLink {
                JSONRawScreen(value: item["data"], title: item["name"].displayString ?? "接口返回")
            } label: {
                Label("查看接口返回", systemImage: "curlybraces")
                    .font(.subheadline)
            }
            .disabled(item["data"].isNull)
        }
    }

    private func check(_ name: String, endpoint: String,
                       operation: () async throws -> JSONValue) async -> JSONValue {
        let started = Date()
        do {
            let data = try await operation()
            let empty = data.isNull || data.isEmptyContainer
            let ok = data.isSuccessFlag && !empty
            return .object([
                "name": .string(name),
                "endpoint": .string(endpoint),
                "ok": .bool(ok),
                "empty": .bool(empty),
                "elapsed_ms": .int(elapsedMilliseconds(since: started)),
                "error": data.errorMessage.map(JSONValue.string) ?? .null,
                "data": data,
            ])
        } catch {
            return failedCheck(name, endpoint: endpoint,
                               message: (error as? LocalizedError)?.errorDescription
                                ?? error.localizedDescription,
                               elapsed: elapsedMilliseconds(since: started))
        }
    }

    private func failedCheck(_ name: String, endpoint: String, message: String,
                             elapsed: Int = 0) -> JSONValue {
        .object([
            "name": .string(name),
            "endpoint": .string(endpoint),
            "ok": .bool(false),
            "empty": .bool(false),
            "elapsed_ms": .int(elapsed),
            "error": .string(message),
            "data": .null,
        ])
    }

    private func elapsedMilliseconds(since date: Date) -> Int {
        max(Int(Date().timeIntervalSince(date) * 1_000), 0)
    }
}
