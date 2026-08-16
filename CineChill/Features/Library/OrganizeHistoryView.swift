import SwiftUI
import Charts

/// 整理记录：筛选、重做、AI 重做、删除、清空。
struct OrganizeHistoryView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    @State private var keyword = ""
    @State private var days = 7
    @State private var category = ""
    @State private var queryKey = 0
    @State private var showClearConfirm = false

    private let dayOptions = [1, 3, 7, 30, 0]

    var body: some View {
        RemoteList(title: "整理记录", cacheKey: "organize-history-\(queryKey)") {
            let api = try session.requireAPI()
            return try await api.organizeHistory.getOrganizeHistory(
                category: category.isEmpty ? nil : category,
                keyword: keyword.isEmpty ? nil : keyword,
                limit: 200,
                page: 1,
                pageSize: 200,
                days: days == 0 ? nil : days,
                compact: true)
        } content: { value, reload in
            filterSection
            let records = value.list("records", "history", "items")
            if records.isEmpty {
                EmptyRow("没有符合条件的记录")
            }
            ForEach(Array(records.enumerated()), id: \.offset) { _, record in
                NavigationLink {
                    OrganizeRecordDetailView(record: record, reload: reload)
                } label: {
                    recordRow(record)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        runner.run("已提交重做", operation: {
                            let api = try session.requireAPI()
                            return try await api.organizeHistory.redoOrganizeHistoryRecords(
                                RedoOrganizeHistoryPayload(historyIds: [recordID(of: record)]))
                        }, onSuccess: { await reload() })
                    } label: {
                        Label("重做", systemImage: "arrow.clockwise")
                    }
                    .tint(.blue)
                    Button {
                        runner.run("已提交 AI 重做", operation: {
                            let api = try session.requireAPI()
                            return try await api.organizeHistory.aiRedoOrganizeHistoryRecords(
                                RedoOrganizeHistoryPayload(historyIds: [recordID(of: record)]))
                        }, onSuccess: { await reload() })
                    } label: {
                        Label("AI 重做", systemImage: "sparkles")
                    }
                    .tint(.purple)
                }
            }
            Section {
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Label("清空记录", systemImage: "trash")
                }
            }
            .confirmationDialog("清空整理记录？只删除历史记录，不会删除已入库的文件。",
                                isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("清空", role: .destructive) {
                    runner.run("已清空", operation: {
                        let api = try session.requireAPI()
                        let categories = category.isEmpty ? nil : [category]
                        return try await api.organizeHistory.clearOrganizeHistoryRecords(
                            ClearOrganizeHistoryPayload(categories: categories))
                    }, onSuccess: { await reload() })
                }
                Button("取消", role: .cancel) {}
            }
        }
        .id(queryKey)
        .searchable(text: $keyword, placement: .navigationBarDrawer(displayMode: .automatic),
                    prompt: "标题关键词")
        .onSubmit(of: .search) { queryKey += 1 }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private var filterSection: some View {
        Section("筛选") {
            Picker("时间范围", selection: $days) {
                ForEach(dayOptions, id: \.self) { day in
                    Text(day == 0 ? "全部" : "近 \(day) 天").tag(day)
                }
            }
            .onChange(of: days) { _, _ in queryKey += 1 }
            Picker("分类", selection: $category) {
                Text("全部").tag("")
                Text("电影").tag("movie")
                Text("剧集").tag("tv")
            }
            .onChange(of: category) { _, _ in queryKey += 1 }
        }
    }

    private func recordID(of record: JSONValue) -> String {
        record.first(of: "id", "record_id", "history_id", "_id").displayString ?? ""
    }

    private func recordRow(_ record: JSONValue) -> some View {
        let status = record.first(of: "status", "state", "result").displayString
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.first(of: "title", "name", "media_title").displayString ?? "—")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                if let status { StatusBadge(status, tone: badgeTone(for: status)) }
            }
            if let file = record.first(of: "source_name", "file_name", "src_name", "source_path").displayString {
                Text(file).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            }
            HStack(spacing: 8) {
                if let type = record.first(of: "category", "media_type", "type").displayString {
                    Text(type).font(.caption2).foregroundStyle(.secondary)
                }
                if let time = record.first(of: "created_at", "time", "organize_time", "date").displayString {
                    Text(Fmt.relative(.string(time))).font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
    }
}

/// 单条整理记录：重做（可先手动指定正确影片）、AI 重做、删除、剧集组查询。
struct OrganizeRecordDetailView: View {
    let record: JSONValue
    let reload: Reload

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var reason = ""
    /// 手动检索选中的影片，作为 recognition_identity 提交给重做接口。
    @State private var identity: JSONValue = .null
    @State private var picking = false

    private var recordID: String {
        record.first(of: "id", "record_id", "history_id", "_id").displayString ?? ""
    }

    var body: some View {
        Form {
            Section("记录") {
                KeyValueRow("标题", record.first(of: "title", "name"))
                KeyValueRow("分类", record.first(of: "category", "media_type"))
                KeyValueRow("状态", record.first(of: "status", "state"))
                KeyValueRow("ID", recordID, monospaced: true)
            }

            identitySection
            redoSection
            episodeGroupSection

            Section {
                Button(role: .destructive) {
                    runner.run("已删除", operation: {
                        let api = try session.requireAPI()
                        return try await api.organizeHistory.deleteOrganizeHistoryRecords(
                            DeleteOrganizeHistoryPayload(ids: [recordID]))
                    }, onSuccess: { await reload() })
                } label: {
                    Label("删除该记录", systemImage: "trash")
                }
            }

        }
        .navigationTitle(record.first(of: "title", "name").displayString ?? "记录")
        .actionFeedback(runner)
        .sheet(isPresented: $picking) {
            NavigationStack {
                OrganizeMediaSearchView(
                    initialQuery: record.first(of: "title", "name", "media_title").displayString ?? "",
                    initialMediaType: record.first(of: "media_type", "category", "type").displayString ?? "auto"
                ) { picked in
                    identity = identityPayload(from: picked)
                }
            }
        }
    }

    @ViewBuilder
    private var identitySection: some View {
        Section {
            if identity.isNull {
                Text("未指定，重做时由服务端按原文件名重新识别。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                KeyValueRow("影片", identity.first(of: "title", "name"))
                KeyValueRow("TMDb ID", identity.first(of: "tmdb_id", "id"), monospaced: true)
                if let type = identity["media_type"].displayString {
                    KeyValueRow("类型", type)
                }
                if let year = identity["year"].displayString, !year.isEmpty {
                    KeyValueRow("年份", year)
                }
                JSONInspector(value: identity, title: "已选条目原始数据")
            }
            Button {
                picking = true
            } label: {
                Label(identity.isNull ? "搜索并指定正确影片" : "重新选择影片",
                      systemImage: "magnifyingglass")
            }
            if !identity.isNull {
                Button(role: .destructive) {
                    identity = .null
                } label: {
                    Label("清除已选影片", systemImage: "xmark.circle")
                }
            }
        } header: {
            Text("识别修正")
        } footer: {
            Text("已选条目会作为 recognition_identity 一起提交，用于纠正识别错误的标题或 TMDb ID。")
        }
    }

    @ViewBuilder
    private var redoSection: some View {
        Section {
            TextField("原因（可留空）", text: $reason)
            Button {
                runner.run("已提交重做", operation: {
                    let api = try session.requireAPI()
                    return try await api.organizeHistory.redoOrganizeHistoryRecord(
                        recordId: recordID, redoBody())
                }, onSuccess: { await reload() })
            } label: {
                Label("重新整理", systemImage: "arrow.clockwise")
            }
            .disabled(recordID.isEmpty)
            Button {
                runner.run("已提交 AI 重做", operation: {
                    let api = try session.requireAPI()
                    return try await api.organizeHistory.aiRedoOrganizeHistoryRecord(
                        recordId: recordID, redoBody())
                }, onSuccess: { await reload() })
            } label: {
                Label("AI 重新识别并整理", systemImage: "sparkles")
            }
            .disabled(recordID.isEmpty)
        } header: {
            Text("重做")
        } footer: {
            Text("重做会按当前配置重新整理该条记录对应的文件，进度可在「自动化 → 任务中心」查看。")
        }
    }

    /// 重做请求体：接口签名为 `JSONValue`，这里用生成的 payload 模型编码，保证键名与服务端一致。
    private func redoBody() -> JSONValue {
        JSONValue.encoding(RedoOrganizeHistoryPayload(
            historyIds: [recordID],
            reason: reason.trimmingCharacters(in: .whitespacesAndNewlines),
            recognitionIdentity: identity.isNull ? nil : identity))
    }

    @ViewBuilder
    private var episodeGroupSection: some View {
        if let tmdbID = record.deepFirst(of: "tmdb_id", "tmdbid", "tmdbId").int, tmdbID > 0 {
            Section {
                NavigationLink {
                    RemoteList(title: "剧集组") {
                        let api = try session.requireAPI()
                        return try await api.organizeHistory.getOrganizeHistoryEpisodeGroups(tmdbId: tmdbID)
                    } content: { value, _ in
                        let groups = value.list("groups", "episode_groups", "results")
                        if groups.isEmpty { EmptyRow() }
                        ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(group.first(of: "name", "title").displayString ?? "—")
                                if let count = group.first(of: "group_count", "episode_count").displayString {
                                    Text(count + " 项").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } label: {
                    Label("查看 TMDB 剧集组", systemImage: "list.number")
                }
            }
        }
    }

    /// 把检索结果整理成 recognition_identity：原样保留服务端字段，并补齐常用键名。
    private func identityPayload(from item: JSONValue) -> JSONValue {
        var payload: JSONValue = .object(item.object ?? [:])
        if let tmdbID = item.first(of: "tmdb_id", "tmdbid", "tmdbId", "id").int, tmdbID > 0 {
            payload["tmdb_id"] = .int(tmdbID)
        }
        if let title = item.first(of: "title", "name", "original_title", "original_name").displayString,
           !title.isEmpty {
            payload["title"] = .string(title)
        }
        if let type = item.first(of: "media_type", "type", "category").displayString, !type.isEmpty {
            payload["media_type"] = .string(type)
        }
        if let date = item.first(of: "year", "release_date", "first_air_date").displayString,
           date.count >= 4 {
            payload["year"] = .string(String(date.prefix(4)))
        }
        return payload
    }
}

/// 影片检索：为重做挑选正确的标题 / TMDb ID。
struct OrganizeMediaSearchView: View {
    let initialQuery: String
    let initialMediaType: String
    let onPick: (JSONValue) -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var mediaType = "auto"
    @State private var yearText = ""
    @State private var results: [JSONValue] = []
    @State private var loading = false
    @State private var message: String?
    @State private var didPrefill = false

    private let types = ["auto", "movie", "tv"]

    var body: some View {
        List {
            Section("检索条件") {
                TextField("标题关键词", text: $query)
                    .textInputAutocapitalization(.never)
                TextField("年份（可留空）", text: $yearText)
                    .keyboardType(.numberPad)
                Picker("媒体类型", selection: $mediaType) {
                    ForEach(types, id: \.self) { type in
                        Text(typeLabel(type)).tag(type)
                    }
                }
                Button {
                    Task { await search() }
                } label: {
                    Label("搜索", systemImage: "magnifyingglass")
                }
                .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || loading)
            }
            if loading {
                LoadingRow()
            }
            if let message {
                Section {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                }
            }
            resultsSection
        }
        .navigationTitle("指定正确影片")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
        }
        .task {
            guard !didPrefill else { return }
            didPrefill = true
            let prefill = initialQuery
            let type = types.contains(initialMediaType) ? initialMediaType : "auto"
            query = prefill
            mediaType = type
            if !prefill.trimmingCharacters(in: .whitespaces).isEmpty {
                await runSearch(prefill, type: type, year: "")
            }
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if !results.isEmpty {
            Section("搜索结果（\(results.count)）") {
                ForEach(Array(results.enumerated()), id: \.offset) { _, item in
                    Button {
                        onPick(item)
                        dismiss()
                    } label: {
                        resultRow(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func resultRow(_ item: JSONValue) -> some View {
        let type = item.first(of: "media_type", "type").displayString
        let year = item.first(of: "year", "release_date", "first_air_date").displayString
        let tmdbID = item.first(of: "tmdb_id", "tmdbid", "id").displayString
        return HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.first(of: "title", "name", "original_title", "original_name").displayString ?? "—")
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 8) {
                    if let type { StatusBadge(typeLabel(type), tone: .info) }
                    if let year, !year.isEmpty {
                        Text(String(year.prefix(4))).font(.caption2).foregroundStyle(.secondary)
                    }
                    if let tmdbID, !tmdbID.isEmpty {
                        Text("TMDb " + tmdbID).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                if let overview = item.first(of: "overview", "summary", "description").displayString,
                   !overview.isEmpty {
                    Text(overview).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer(minLength: 4)
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.tint)
        }
        .contentShape(Rectangle())
    }

    private func typeLabel(_ raw: String) -> String {
        switch raw.lowercased() {
        case "movie", "电影": return "电影"
        case "tv", "series", "剧集": return "剧集"
        case "auto": return "自动"
        default: return raw
        }
    }

    private func search() async {
        await runSearch(query, type: mediaType, year: yearText)
    }

    private func runSearch(_ rawQuery: String, type: String, year rawYear: String) async {
        let text = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !loading else { return }
        loading = true
        message = nil
        do {
            let api = try session.requireAPI()
            let year = rawYear.trimmingCharacters(in: .whitespacesAndNewlines)
            let response = try await api.organizeHistory.searchOrganizeHistoryMedia(
                query: text,
                mediaType: type,
                year: year.isEmpty ? nil : year,
                limit: 20)
            results = response.list("results", "items", "media", "candidates")
            if results.isEmpty { message = "没有匹配的条目" }
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            results = []
            message = error.errorDescription
        } catch {
            results = []
            message = error.localizedDescription
        }
        loading = false
    }
}

/// 整理概览：按天统计。
private struct OrganizeTrendPoint: Identifiable {
    let id: String
    let label: String
    let count: Int
}

struct OrganizeSummaryView: View {
    @EnvironmentObject private var session: AppSession
    @State private var days = 30
    @State private var keyword = ""
    @State private var appliedKeyword = ""
    @State private var queryKey = 0

    var body: some View {
        RemoteList(title: "整理概览", cacheKey: "organize-summary-\(queryKey)") {
            let api = try session.requireAPI()
            return try await api.organizeHistory.getOrganizeHistorySummary(
                days: days,
                keyword: appliedKeyword.isEmpty ? nil : appliedKeyword)
        } content: { value, _ in
            rangeSection(value)
            overviewSection(value)
            categorySection(value)
            trendSection(value)
        }
        .id(queryKey)
        .searchable(text: $keyword,
                    placement: .navigationBarDrawer(displayMode: .automatic),
                    prompt: "标题或文件关键词")
        .onSubmit(of: .search) { applyKeyword() }
        .onChange(of: keyword) { _, newValue in
            if newValue.isEmpty, !appliedKeyword.isEmpty {
                appliedKeyword = ""
                queryKey += 1
            }
        }
    }

    @ViewBuilder
    private func rangeSection(_ value: JSONValue) -> some View {
        Section("统计范围") {
            Picker("统计天数", selection: $days) {
                ForEach([7, 14, 30, 90], id: \.self) { Text("近 \($0) 天").tag($0) }
            }
            .onChange(of: days) { _, _ in queryKey += 1 }

            let start = value.first(of: "start_date", "start", "from").displayString ?? "—"
            let end = value.first(of: "end_date", "end", "to").displayString ?? "—"
            KeyValueRow("日期", "\(start) 至 \(end)", monospaced: true)
            if !appliedKeyword.isEmpty {
                KeyValueRow("关键词", appliedKeyword)
            }
        }
    }

    @ViewBuilder
    private func overviewSection(_ value: JSONValue) -> some View {
        let categories = categoryItems(value)
        let categoryTotal = categories.reduce(0) {
            $0 + ($1.first(of: "count", "total", "value").int ?? 0)
        }
        let total = value.first(of: "total", "count", "records").int ?? categoryTotal
        let responseDays = value.first(of: "days", "range_days").int ?? days

        Section("概览") {
            KeyValueRow("整理记录", "\(total) 条")
            KeyValueRow("统计周期", "近 \(responseDays) 天")
            if !value["updated_at"].isNull {
                KeyValueRow("更新时间", Fmt.fullDateTime(value["updated_at"]))
            }
        }
    }

    @ViewBuilder
    private func categorySection(_ value: JSONValue) -> some View {
        let categories = categoryItems(value)
        Section("分类统计") {
            if categories.isEmpty {
                EmptyRow("暂无分类统计")
            } else {
                ForEach(Array(categories.enumerated()), id: \.offset) { _, item in
                    let key = item.first(of: "key", "category", "type").displayString ?? ""
                    let label = item.first(of: "label", "name", "title").displayString
                        ?? categoryLabel(key)
                    let count = item.first(of: "count", "total", "value").int ?? 0
                    let color = categoryColor(item, key: key)
                    HStack(spacing: 12) {
                        Image(systemName: categoryIcon(key))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(color)
                            .frame(width: 30, height: 30)
                            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        Text(label)
                        Spacer()
                        Text("\(count) 条")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(count > 0 ? color : Color.gray)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func trendSection(_ value: JSONValue) -> some View {
        let points = trendPoints(value)
        Section("每日趋势") {
            if points.isEmpty || points.allSatisfy({ $0.count == 0 }) {
                EmptyRow("该范围内暂无整理记录")
            } else {
                Chart(points) { point in
                    AreaMark(
                        x: .value("日期", shortDate(point.label)),
                        y: .value("数量", point.count)
                    )
                    .foregroundStyle(.blue.opacity(0.12))
                    .interpolationMethod(.monotone)

                    LineMark(
                        x: .value("日期", shortDate(point.label)),
                        y: .value("数量", point.count)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                }
                .chartYScale(domain: 0...max(points.map(\.count).max() ?? 0, 1))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(points.count, 6)))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 210)
                .padding(.vertical, 6)
            }
        }
    }

    private func applyKeyword() {
        let normalized = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized != appliedKeyword else { return }
        appliedKeyword = normalized
        queryKey += 1
    }

    private func categoryItems(_ value: JSONValue) -> [JSONValue] {
        value.list("categories", "category_stats", "category_counts")
    }

    private func trendPoints(_ value: JSONValue) -> [OrganizeTrendPoint] {
        let trend = value.first(of: "trend", "daily", "summary", "items")
        if let items = trend.array {
            return items.enumerated().map { index, item in
                let label = item.first(of: "date", "day", "label", "name").displayString
                    ?? String(index + 1)
                return OrganizeTrendPoint(id: "\(label)-\(index)",
                                          label: label, count: trendCount(item))
            }
        }
        if let items = trend.object {
            return items.sorted(by: { $0.key < $1.key }).enumerated().map { index, entry in
                OrganizeTrendPoint(id: "\(entry.key)-\(index)",
                                   label: entry.key, count: trendCount(entry.value))
            }
        }
        return []
    }

    private func trendCount(_ item: JSONValue) -> Int {
        if let count = item.first(of: "total", "count", "value", "records").int {
            return count
        }
        for key in ["categories", "counts", "values"] {
            if let values = item[key].object {
                return values.values.compactMap(\.int).reduce(0, +)
            }
        }
        guard let values = item.object else { return item.int ?? 0 }
        let ignored = Set(["date", "day", "label", "name", "timestamp"])
        return values.compactMap { key, value in ignored.contains(key) ? nil : value.int }
            .reduce(0, +)
    }

    private func shortDate(_ value: String) -> String {
        let parts = value.split(separator: "-")
        guard parts.count >= 3 else { return value }
        return "\(parts[parts.count - 2])-\(parts[parts.count - 1])"
    }

    private func categoryLabel(_ key: String) -> String {
        switch key {
        case "organize_success": return "整理成功"
        case "organize_failed": return "整理失败"
        case "wash_success": return "洗版成功"
        case "wash_failed": return "洗版失败"
        case "sha1_duplicate": return "SHA1 重复"
        case "strm_generated": return "STRM 生成"
        case "skipped": return "跳过记录"
        case "ai_organize": return "AI 整理"
        default: return key.isEmpty ? "其他" : key
        }
    }

    private func categoryIcon(_ key: String) -> String {
        switch key {
        case "organize_success": return "checkmark.circle.fill"
        case "organize_failed": return "xmark.circle.fill"
        case "wash_success": return "arrow.triangle.2.circlepath.circle.fill"
        case "wash_failed": return "exclamationmark.triangle.fill"
        case "sha1_duplicate": return "doc.on.doc.fill"
        case "strm_generated": return "doc.badge.gearshape.fill"
        case "skipped": return "forward.fill"
        case "ai_organize": return "sparkles"
        default: return "tray.full.fill"
        }
    }

    private func categoryColor(_ item: JSONValue, key: String) -> Color {
        let tone = item.first(of: "tone", "status", "color").displayString?.lowercased() ?? ""
        if tone.contains("success") || key.hasSuffix("_success") { return .green }
        if tone.contains("danger") || tone.contains("error") || key == "organize_failed" { return .red }
        if tone.contains("warning") || key == "wash_failed" || key == "sha1_duplicate" { return .orange }
        if tone.contains("muted") || key == "skipped" { return .gray }
        if key == "ai_organize" { return .purple }
        return .blue
    }
}
