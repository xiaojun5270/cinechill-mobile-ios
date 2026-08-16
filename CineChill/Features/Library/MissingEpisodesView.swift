import SwiftUI

/// 缺集统计：列出缺失剧集，可手动标记完成。
struct MissingEpisodesView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var seasonMode = "all"
    @State private var queryKey = 0

    var body: some View {
        RemoteList(title: "缺集统计", subtitle: "统计结果由服务端缓存，需要最新数据时点右上角刷新",
                   cacheKey: "missing-episodes-\(queryKey)") {
            let api = try session.requireAPI()
            return try await api.discover.libraryMissingEpisodeStats(
                refresh: nil, start: 0, summaryOnly: nil, seasonMode: seasonMode)
        } content: { value, reload in
            Section("模式") {
                Picker("季模式", selection: $seasonMode) {
                    Text("全部季").tag("all")
                    Text("仅最新季").tag("latest")
                }
                .onChange(of: seasonMode) { _, _ in queryKey += 1 }
            }

            summaryRows(value)

            let series = value.list("series", "shows", "missing", "items")
            if series.isEmpty {
                EmptyRow("没有检测到缺失剧集")
            }
            ForEach(Array(series.enumerated()), id: \.offset) { _, show in
                NavigationLink {
                    MissingSeriesDetailView(show: show, reload: reload)
                } label: {
                    seriesRow(show)
                }
            }
        }
        .id(queryKey)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    runner.run("已请求重新统计", operation: {
                        let api = try session.requireAPI()
                        return try await api.discover.libraryMissingEpisodeStats(
                            refresh: 1, start: 0, summaryOnly: nil, seasonMode: seasonMode)
                    }, onSuccess: { queryKey += 1 })
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func summaryRows(_ value: JSONValue) -> some View {
        let total = value.deepFirst(of: "total_missing", "missing_total", "total")
        let showCount = value.deepFirst(of: "series_count", "show_count")
        if !total.isNull || !showCount.isNull {
            Section("汇总") {
                if !showCount.isNull { KeyValueRow("涉及剧集", Fmt.count(showCount)) }
                if !total.isNull { KeyValueRow("缺失集数", Fmt.count(total)) }
                if let updated = value.deepFirst(of: "updated_at", "last_update", "cached_at").displayString {
                    KeyValueRow("统计时间", Fmt.relative(.string(updated)))
                }
            }
        }
    }

    private func seriesRow(_ show: JSONValue) -> some View {
        let missing = show.deepFirst(of: "missing_count", "missing", "missing_total").int ?? 0
        return HStack(spacing: 10) {
            RemoteImage(url: Artwork.url(for: show, api: session.api, session: session),
                        placeholderIcon: "tv")
                .frame(width: 36, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 3) {
                Text(show.first(of: "title", "name", "series_name").displayString ?? "—")
                    .font(.subheadline)
                    .lineLimit(1)
                if let year = show.first(of: "year", "first_air_date").displayString {
                    Text(year).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if missing > 0 { StatusBadge("缺 \(missing) 集", tone: .warning) }
        }
    }
}

/// 单剧缺集明细与手动标记。
struct MissingSeriesDetailView: View {
    let show: JSONValue
    let reload: Reload

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    var body: some View {
        Form {
            Section("剧集") {
                KeyValueRow("标题", show.first(of: "title", "name"))
                KeyValueRow("TMDB", show.deepFirst(of: "tmdb_id", "tmdbid"))
                KeyValueRow("缺失", Fmt.count(show.deepFirst(of: "missing_count", "missing")))
            }

            let seasons = show.list("seasons", "season_list")
            if !seasons.isEmpty {
                Section("分季") {
                    ForEach(Array(seasons.enumerated()), id: \.offset) { _, season in
                        seasonRow(season)
                    }
                }
            }

            Section {
                Button {
                    markComplete(season: nil)
                } label: {
                    Label("整剧标记为已完结", systemImage: "checkmark.circle")
                }
            } footer: {
                Text("标记后该剧（或该季）不再计入缺集统计，适用于官方已完结但集数信息不准确的情况。")
            }

        }
        .navigationTitle(show.first(of: "title", "name").displayString ?? "缺集详情")
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func seasonRow(_ season: JSONValue) -> some View {
        let number = season.first(of: "season_number", "season", "index").int ?? 0
        let missingList = season.deepFirst(of: "missing_episodes", "missing_list").array ?? []
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("第 \(number) 季").font(.subheadline.weight(.medium))
                Spacer()
                Button("标记完结") { markComplete(season: number) }
                    .font(.caption)
                    .buttonStyle(.borderless)
            }
            if !missingList.isEmpty {
                Text("缺失：" + missingList.compactMap { $0.displayString }.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if let count = season.deepFirst(of: "missing_count", "missing").int, count > 0 {
                Text("缺 \(count) 集").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private func markComplete(season: Int?) {
        runner.run("已标记", operation: {
            let api = try session.requireAPI()
            var body: [String: JSONValue] = [:]
            if let tmdb = show.deepFirst(of: "tmdb_id", "tmdbid").int { body["tmdb_id"] = .int(tmdb) }
            if let title = show.first(of: "title", "name").string { body["title"] = .string(title) }
            if let seriesID = show.deepFirst(of: "series_id", "emby_series_id", "Id").string {
                body["series_id"] = .string(seriesID)
            }
            if let season { body["season_number"] = .int(season) }
            body["manual_complete"] = .bool(true)
            return try await api.discover.setMissingEpisodeManualComplete(.object(body))
        }, onSuccess: { await reload() })
    }
}

/// 转存历史：手动转存链接、查看与清空历史。
struct TransferHistoryView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var link = ""
    @State private var showClearConfirm = false

    var body: some View {
        RemoteList(title: "转存历史") {
            let api = try session.requireAPI()
            return try await api.transfer.getTransferHistory()
        } content: { value, reload in
            Section("手动转存") {
                TextField("115 分享链接", text: $link, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    runner.run("已提交转存", operation: {
                        let api = try session.requireAPI()
                        return try await api.transfer.manualTransfer(ManualTransferRequest(link: link))
                    }, onSuccess: {
                        link = ""
                        await reload()
                    })
                } label: {
                    Label("开始转存", systemImage: "arrow.down.circle")
                }
                .disabled(link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            let records = value.list("history", "records", "items")
            if records.isEmpty {
                EmptyRow("暂无转存记录")
            }
            ForEach(Array(records.enumerated()), id: \.offset) { _, record in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(record.first(of: "name", "title", "file_name").displayString ?? "—")
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        if let status = record.first(of: "status", "state").displayString {
                            StatusBadge(status, tone: badgeTone(for: status))
                        }
                    }
                    if let link = record.first(of: "link", "share_link", "url").displayString {
                        Text(link).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                    if let time = record.first(of: "created_at", "time", "date").displayString {
                        Text(Fmt.relative(.string(time))).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }

            if !records.isEmpty {
                Section {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("清空转存历史", systemImage: "trash")
                    }
                }
                .confirmationDialog("清空转存历史？", isPresented: $showClearConfirm, titleVisibility: .visible) {
                    Button("清空", role: .destructive) {
                        runner.run("已清空", operation: {
                            let api = try session.requireAPI()
                            return try await api.transfer.clearTransferHistory()
                        }, onSuccess: { await reload() })
                    }
                    Button("取消", role: .cancel) {}
                }
            }
        }
        .actionFeedback(runner)
    }
}
