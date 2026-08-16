import SwiftUI

/// 订阅事件流。
struct SubscriptionEventsView: View {
    @EnvironmentObject private var session: AppSession
    @State private var eventType = ""
    @State private var queryKey = 0

    private let types = ["", "matched", "subscribed", "downloaded", "failed"]

    var body: some View {
        RemoteList(title: "订阅事件") {
            let api = try session.requireAPI()
            return try await api.subscriptions.listSubscriptionEvents(
                limit: 200,
                eventType: eventType.isEmpty ? nil : eventType,
                subscriptionIds: nil, tmdbId: nil, mediaType: nil)
        } content: { value, _ in
            Section("筛选") {
                Picker("事件类型", selection: $eventType) {
                    ForEach(types, id: \.self) { Text($0.isEmpty ? "全部" : $0).tag($0) }
                }
                .onChange(of: eventType) { _, _ in queryKey += 1 }
            }
            let events = value.list("events", "items")
            if events.isEmpty { EmptyRow("没有事件") }
            ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.first(of: "title", "name", "media_title").displayString ?? "—")
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        if let type = event.first(of: "event_type", "type").displayString {
                            StatusBadge(type, tone: badgeTone(for: type))
                        }
                    }
                    if let message = event.first(of: "message", "detail", "description").displayString {
                        Text(message).font(.caption2).foregroundStyle(.secondary).lineLimit(3)
                    }
                    if let time = event.first(of: "created_at", "time", "timestamp").displayString {
                        Text(Fmt.relative(.string(time))).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .id(queryKey)
    }
}

/// 订阅动态。
struct SubscriptionActivityView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "订阅动态") {
            let api = try session.requireAPI()
            return try await api.subscriptions.getSubscriptionActivity(
                subscriptionIds: nil, tmdbId: nil, mediaType: nil, title: nil, limit: 100)
        } content: { value, _ in
            let items = value.list("activity", "items", "records")
            if items.isEmpty {
                Section { JSONFieldList(value: value) }
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.first(of: "title", "name").displayString ?? "—")
                            .font(.subheadline)
                        if let summary = item.first(of: "summary", "message", "status").displayString {
                            Text(summary).font(.caption2).foregroundStyle(.secondary)
                        }
                        if let time = item.first(of: "updated_at", "created_at", "time").displayString {
                            Text(Fmt.relative(.string(time))).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }
}

/// MoviePilot：连接配置、站点管理、订阅进度、退订与历史记录。
struct MoviePilotView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    var body: some View {
        RemoteList(title: "MoviePilot") {
            let api = try session.requireAPI()
            let config = await Probe.json { try await api.moviePilot.getMpConfig() }
            let subs = await Probe.json { try await api.moviePilot.mpListSubscriptions() }
            let requests = episodeProgressRequests(subs.list("subscriptions", "items", "data"))
            let progress = requests.isEmpty
                ? JSONValue.object(["items": .array([])])
                : await Probe.json { try await api.subscriptions.getEpisodeProgress(items: requests) }
            return JSONValue.object([
                "config": config,
                "subscriptions": subs,
                "episode_progress": progress,
            ])
        } content: { value, reload in
            Section("连接") {
                KeyValueRow("地址", value["config"].deepFirst(of: "mp_url", "url"))
                KeyValueRow("用户名", value["config"].deepFirst(of: "mp_username", "username"))
                NavigationLink {
                    MoviePilotConfigView()
                } label: {
                    Label("修改连接配置", systemImage: "slider.horizontal.3")
                }
                NavigationLink {
                    MoviePilotSitesView()
                } label: {
                    Label("站点管理", systemImage: "network")
                }
                Button {
                    runner.run("连接正常") {
                        let api = try session.requireAPI()
                        return try await api.moviePilot.testMpConnection()
                    }
                } label: {
                    Label("测试连接", systemImage: "bolt.horizontal")
                }
            }

            let subs = value["subscriptions"].list("subscriptions", "items", "data")
            let progress = value["episode_progress"].list("items")
            Section("订阅（\(subs.count)）") {
                if subs.isEmpty { EmptyRow("没有订阅") }
                ForEach(Array(subs.enumerated()), id: \.offset) { _, sub in
                    subscriptionRow(sub, progress: episodeProgress(for: sub, in: progress), reload: reload)
                }
            }

            let completed = value["subscriptions"].list("completed_rss_items")
            let deleted = value["subscriptions"].list("deleted_auto_items")
            Section("订阅记录") {
                NavigationLink {
                    MoviePilotSubscriptionRecordsView(workspace: "history", title: "已完成记录")
                } label: {
                    HStack {
                        Label("已完成", systemImage: "checkmark.circle")
                        Spacer()
                        Text(String(completed.count)).foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    MoviePilotSubscriptionRecordsView(workspace: "deleted", title: "已删除记录")
                } label: {
                    HStack {
                        Label("已删除", systemImage: "trash.circle")
                        Spacer()
                        Text(String(deleted.count)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func subscriptionRow(_ sub: JSONValue, progress: JSONValue, reload: Reload) -> some View {
        let tmdbID = sub.deepFirst(of: "tmdbid", "tmdb_id").int
        let type = moviePilotMediaType(sub.first(of: "type", "type_name", "media_type").displayString)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(sub.first(of: "name", "title").displayString ?? "—")
                    .font(.subheadline)
                Spacer()
                StatusBadge(type == "tv" ? "电视剧" : "电影", tone: .info)
            }
            HStack(spacing: 8) {
                if let year = sub.first(of: "year").displayString { Text(year) }
                if let season = sub.first(of: "season").int, season > 0 { Text("第 \(season) 季") }
                if let tmdbID { Text("TMDB \(tmdbID)") }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            if type == "tv", let total = progress.first(of: "total", "total_count").int, total > 0 {
                let present = progress.first(of: "present", "present_count").int ?? 0
                let missing = progress.first(of: "missing", "missing_count").int ?? max(0, total - present)
                VStack(alignment: .leading, spacing: 3) {
                    ProgressView(value: Double(min(present, total)), total: Double(total))
                    HStack {
                        Text("已入库 \(present) / \(total) 集")
                        Spacer()
                        if missing > 0 { Text("缺 \(missing) 集").foregroundStyle(.orange) }
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    let detail = missingSeasonSummary(progress)
                    if !detail.isEmpty {
                        Text(detail).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
            if let tmdbID {
                HStack(spacing: 16) {
                    Button("检查状态") {
                        runner.run(nil) {
                            let api = try session.requireAPI()
                            return try await api.moviePilot.mpCheckSubscribe(
                                tmdbid: tmdbID, typeName: type, season: sub.first(of: "season").int)
                        }
                    }
                    Button("退订") {
                        runner.run("已退订", operation: {
                            let api = try session.requireAPI()
                            return try await api.moviePilot.mpUnsubscribe(
                                tmdbid: tmdbID, typeName: type, season: sub.first(of: "season").int)
                        }, onSuccess: { await reload() })
                    }
                    .foregroundStyle(.red)
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
        }
    }
}

/// MP 自动订阅的已完成/已删除记录，清除后允许自动化重新订阅。
struct MoviePilotSubscriptionRecordsView: View {
    let workspace: String
    let title: String

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var pending: PendingSubscriptionRecordClear?

    var body: some View {
        RemoteList(title: title) {
            let api = try session.requireAPI()
            return try await api.moviePilot.mpListSubscriptions()
        } content: { value, reload in
            let key = workspace == "deleted" ? "deleted_auto_items" : "completed_rss_items"
            let records = value.list(key)
            Section("记录（\(records.count)）") {
                if records.isEmpty { EmptyRow("暂无记录") }
                ForEach(Array(records.enumerated()), id: \.offset) { _, record in
                    recordRow(record, reload: reload)
                }
            }
            if !records.isEmpty {
                Section {
                    Button(role: .destructive) {
                        pending = PendingSubscriptionRecordClear(record: .null, clearAll: true, reload: reload)
                    } label: {
                        Label("清空全部记录", systemImage: "trash")
                    }
                } footer: {
                    Text("只清除自动订阅状态，不会删除媒体文件；清除后 RSS 或真实库任务可以重新添加订阅。")
                }
            }
        }
        .actionFeedback(runner)
        .confirmationDialog(pending?.clearAll == true ? "清空全部记录？" : "清除这条记录？",
                            isPresented: Binding(get: { pending != nil },
                                                 set: { if !$0 { pending = nil } }),
                            titleVisibility: .visible) {
            Button(pending?.clearAll == true ? "全部清除" : "清除记录", role: .destructive) {
                clearPending()
            }
            Button("取消", role: .cancel) { pending = nil }
        } message: {
            Text("清除后会解除自动订阅拦截，后续任务可能重新创建该订阅。")
        }
    }

    @ViewBuilder
    private func recordRow(_ record: JSONValue, reload: Reload) -> some View {
        let type = moviePilotMediaType(record.first(of: "media_type", "type", "type_name").displayString)
        let tmdbID = record.first(of: "tmdb_id", "tmdbid").displayString ?? ""
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.first(of: "display_title", "title", "name").displayString ?? "—")
                    .font(.subheadline)
                    .lineLimit(2)
                Spacer()
                StatusBadge(type == "tv" ? "电视剧" : "电影", tone: .info)
            }
            HStack(spacing: 8) {
                if let year = record.first(of: "year").displayString { Text(year) }
                if let season = record.first(of: "season").int, season > 0 { Text("第 \(season) 季") }
                if !tmdbID.isEmpty { Text("TMDB " + tmdbID) }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            Button("清除记录") {
                pending = PendingSubscriptionRecordClear(record: record, clearAll: false, reload: reload)
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
            .disabled(tmdbID.isEmpty)
        }
    }

    private func clearPending() {
        guard let target = pending else { return }
        pending = nil
        let tmdbID = target.record.first(of: "tmdb_id", "tmdbid").displayString
        let type = moviePilotMediaType(target.record.first(of: "media_type", "type", "type_name").displayString)
        runner.run(target.clearAll ? "已清空记录" : "已清除记录") {
            let api = try session.requireAPI()
            return try await api.moviePilot.clearSubscriptionRecords(
                workspace: workspace,
                clearAll: target.clearAll,
                tmdbID: tmdbID,
                typeName: type)
        } onSuccess: {
            await target.reload()
        }
    }
}

private struct PendingSubscriptionRecordClear {
    let record: JSONValue
    let clearAll: Bool
    let reload: Reload
}

private func moviePilotMediaType(_ raw: String?) -> String {
    let value = (raw ?? "").lowercased()
    return ["tv", "tvshows", "series", "season", "episode", "电视剧", "剧集"].contains(value)
        ? "tv" : "movie"
}

private func episodeProgressRequests(_ subscriptions: [JSONValue]) -> [JSONValue] {
    var seen: Set<String> = []
    var result: [JSONValue] = []
    for item in subscriptions {
        guard moviePilotMediaType(item.first(of: "media_type", "type", "type_name").displayString) == "tv",
              let tmdbID = item.first(of: "tmdb_id", "tmdbid").displayString,
              !tmdbID.isEmpty,
              tmdbID.allSatisfy(\.isNumber),
              normalizedEpisodeProgress(item["episode_progress"]) == nil,
              seen.insert(tmdbID).inserted else { continue }
        let season = item.first(of: "season").int
        var payload: [String: JSONValue] = [
            "tmdb_id": .string(tmdbID),
            "media_type": .string("tv"),
            "title": .string(String((item.first(of: "title", "display_title", "original_title", "name")
                .displayString ?? "").prefix(300))),
            "year": .string(String((item.first(of: "year").displayString ?? "").prefix(16))),
        ]
        if let season, season > 0 { payload["season"] = .int(season) }
        result.append(.object(payload))
    }
    return result
}

private func episodeProgress(for subscription: JSONValue, in items: [JSONValue]) -> JSONValue {
    if let embedded = normalizedEpisodeProgress(subscription["episode_progress"], fallback: subscription) {
        return embedded
    }

    let candidates = items.compactMap { normalizedEpisodeProgress($0) }
    let tmdbID = subscription.first(of: "tmdb_id", "tmdbid", "tmdbId").displayString ?? ""
    let exact = candidates.filter { $0.first(of: "tmdb_id").displayString == tmdbID && !tmdbID.isEmpty }
    let matched = exact.isEmpty
        ? candidates.filter { episodeProgressTitleKey($0) == episodeProgressTitleKey(subscription) }
        : exact
    return matched.max { lhs, rhs in
        let left = (lhs["total"].int ?? 0, lhs["present"].int ?? 0)
        let right = (rhs["total"].int ?? 0, rhs["present"].int ?? 0)
        return left < right
    } ?? .null
}

private func normalizedEpisodeProgress(_ value: JSONValue, fallback: JSONValue = .null) -> JSONValue? {
    guard value.object != nil else { return nil }
    let rawTotal = value.first(of: "rawTotalEpisodes", "raw_total_episodes").int
    let reportedTotal = value.first(of: "total", "total_count", "totalEpisodes", "total_episodes").int ?? 0
    let total = (rawTotal ?? 0) > 0 ? rawTotal ?? 0 : reportedTotal
    guard total > 0 else { return nil }

    let presentValue = value.first(of: "present", "present_count", "presentEpisodes", "present_episodes").int ?? 0
    let missingValue = value.first(of: "missing", "missing_count", "rawMissingEpisodes",
                                      "raw_missing_episodes", "missingEpisodes", "missing_episodes").int
    let present = max(0, min(presentValue, total))
    let missing = max(0, min(missingValue ?? total - present, total))
    let item = value["item"]
    var result: [String: JSONValue] = [
        "total": .int(total),
        "present": .int(present),
        "missing": .int(missing),
        "tmdb_id": .string(value.first(of: "tmdbId", "tmdb_id").displayString
            ?? item.first(of: "tmdb_id", "_tmdb_id", "id").displayString
            ?? fallback.first(of: "tmdb_id", "tmdbid", "tmdbId").displayString
            ?? ""),
        "title": .string(value.first(of: "title").displayString
            ?? item.first(of: "name", "Name").displayString
            ?? fallback.first(of: "title", "display_title", "original_title", "name").displayString
            ?? ""),
        "year": .string(value.first(of: "year").displayString
            ?? item.first(of: "year", "ProductionYear").displayString
            ?? fallback.first(of: "year").displayString
            ?? ""),
    ]
    if !value["seasons"].isNull { result["seasons"] = value["seasons"] }
    return .object(result)
}

private func episodeProgressTitleKey(_ value: JSONValue) -> String {
    let title = value.first(of: "title", "display_title", "original_title", "name")
        .displayString?.lowercased().filter { $0.isLetter || $0.isNumber } ?? ""
    let year = String((value.first(of: "year").displayString ?? "").prefix(4))
    return title.isEmpty ? "" : title + ":" + year
}

private func missingSeasonSummary(_ progress: JSONValue) -> String {
    guard let seasons = progress["seasons"].object else { return "" }
    return seasons.keys.sorted().prefix(4).compactMap { key in
        guard let count = seasons[key]?.array?.count, count > 0 else { return nil }
        let label = key.lowercased().hasPrefix("s") ? key.uppercased() : "S" + key
        return "\(label) 缺 \(count) 集"
    }.joined(separator: " · ")
}

/// MoviePilot 连接配置。
struct MoviePilotConfigView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var url = ""
    @State private var username = ""
    @State private var password = ""
    @State private var loaded = false

    var body: some View {
        Form {
            Section("连接信息") {
                TextField("MoviePilot 地址", text: $url)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("用户名", text: $username)
                    .textInputAutocapitalization(.never)
                SecureField("密码（留空表示不修改）", text: $password)
            }
            Section {
                Button("保存") {
                    runner.run("已保存") {
                        let api = try session.requireAPI()
                        return try await api.moviePilot.saveMpConfig(
                            MoviePilotConfigModel(mpUrl: url, mpUsername: username, mpPassword: password))
                    }
                }
                .disabled(url.isEmpty)
            } footer: {
                Text("地址形如 http://192.168.1.10:3000。密码保存在服务端配置中。")
            }
        }
        .navigationTitle("MoviePilot 配置")
        .actionFeedback(runner)
        .task {
            guard !loaded, let api = session.api else { return }
            loaded = true
            let config = await Probe.json { try await api.moviePilot.getMpConfig() }
            url = config.deepFirst(of: "mp_url", "url").string ?? ""
            username = config.deepFirst(of: "mp_username", "username").string ?? ""
        }
    }
}
