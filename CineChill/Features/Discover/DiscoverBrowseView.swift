import SwiftUI

// MARK: - 选项模型

/// `/api/discover/sources` 返回的可用数据源。
private struct SourceOption: Identifiable, Hashable {
    let id: String
    let name: String
}

/// `/api/discover/genres` 返回的类型。
private struct GenreOption: Identifiable, Hashable {
    let id: Int
    let name: String
}

/// 兼容数组、对象数组与「键 → 对象」三种数据源写法。
private func discoverSourceOptions(_ value: JSONValue) -> [SourceOption] {
    var result: [SourceOption] = []
    var seen: Set<String> = []
    func add(key: String?, name: String?) {
        guard let key, !key.isEmpty, !seen.contains(key) else { return }
        seen.insert(key)
        let label = name.flatMap { $0.isEmpty ? nil : $0 } ?? key
        result.append(SourceOption(id: key, name: label))
    }
    for item in value.list("sources", "items", "providers") {
        if let text = item.string {
            add(key: text, name: text)
        } else {
            add(key: item.first(of: "key", "source_key", "id", "value", "slug").displayString,
                name: item.first(of: "name", "title", "label", "display_name").displayString)
        }
    }
    if result.isEmpty {
        let container = value["sources"].object != nil ? value["sources"] : value
        for pair in container.sortedPairs {
            if pair.value.object != nil {
                add(key: pair.key, name: pair.value.first(of: "name", "title", "label").displayString)
            } else if let text = pair.value.string {
                add(key: pair.key, name: text)
            }
        }
    }
    return result
}

/// 类型列表可能是 `{"genres": [...]}`、`{"movie": [...], "tv": [...]}` 或直接数组。
private func discoverGenreOptions(_ value: JSONValue) -> [GenreOption] {
    var result: [GenreOption] = []
    var seen: Set<Int> = []
    func add(_ item: JSONValue) {
        guard let id = item.first(of: "id", "genre_id", "value").int, !seen.contains(id) else { return }
        seen.insert(id)
        let name = item.first(of: "name", "title", "label", "chinese_name").displayString ?? "类型 \(id)"
        result.append(GenreOption(id: id, name: name))
    }
    for container in [value, value["genres"], value["data"]] {
        for item in container.list("genres", "items") { add(item) }
        for key in ["movie", "movies", "tv", "series"] {
            for item in container[key].list("genres", "items") { add(item) }
        }
    }
    return result
}

/// 浏览发现：数据源选择 + 类型筛选 + TMDb 通用发现，并汇总三个发现工具。
struct DiscoverBrowseView: View {
    @EnvironmentObject private var session: AppSession

    @State private var mode: BrowseMode = .genre
    @State private var mediaType = "movie"
    @State private var genreID = 0
    @State private var sourceKey = ""
    @State private var sortBy = "popularity.desc"
    @State private var language = ""
    @State private var minRating = 0.0
    @State private var page = 1
    @State private var queryKey = 0

    private enum BrowseMode: String, CaseIterable, Identifiable, Hashable {
        case genre, tmdb

        var id: String { rawValue }
        var title: String { self == .genre ? "按类型" : "TMDb 发现" }
    }

    var body: some View {
        RemoteScroll(title: "浏览发现") {
            let api = try session.requireAPI()
            async let sourcesRequest = Probe.json { try await api.discover.getDiscoverSources() }
            async let genresRequest = Probe.json { try await api.discover.getGenres() }
            async let resultsRequest = loadResults(api: api)
            let (sources, genres, results) = await (sourcesRequest, genresRequest, resultsRequest)
            return JSONValue.object(["sources": sources, "genres": genres, "results": results])
        } content: { value, _ in
            sourceCard(value["sources"])
            filterCard(value["genres"])
            resultCard(value["results"])
            toolCard
        }
        .id(queryKey)
    }

    @MainActor
    private func loadResults(api: CineChillAPI) async -> JSONValue {
        switch mode {
        case .genre:
            guard genreID > 0 else { return .null }
            return await Probe.json {
                try await api.discover.discoverByGenre(genreId: genreID, mediaType: mediaType, page: page)
            }
        case .tmdb:
            return await Probe.json {
                try await api.discover.tmdbDiscover(mediaType: mediaType,
                                                   sortBy: sortBy,
                                                   withGenres: genreID > 0 ? String(genreID) : nil,
                                                   withKeywords: nil,
                                                   withOriginalLanguage: language.isEmpty ? nil : language,
                                                   withWatchProviders: nil,
                                                   voteAverage: minRating > 0 ? minRating : nil,
                                                   voteCount: nil,
                                                   releaseDate: nil,
                                                   page: page)
            }
        }
    }

    private func resetPage() {
        page = 1
        queryKey += 1
    }

    // MARK: - 数据源

    @ViewBuilder
    private func sourceCard(_ sources: JSONValue) -> some View {
        let options = discoverSourceOptions(sources)
        CardSection(title: "数据源", systemImage: "square.stack.3d.up") {
            VStack(alignment: .leading, spacing: 10) {
                if options.isEmpty {
                    Text("服务端未返回可用数据源").font(.footnote).foregroundStyle(.secondary)
                } else {
                    Picker("数据源", selection: $sourceKey) {
                        Text("未选择").tag("")
                        ForEach(options) { Text($0.name).tag($0.id) }
                    }
                    .pickerStyle(.menu)
                    KeyValueRow("可用来源", "\(options.count) 个")
                    sourceLink(options)
                }
            }
            .font(.subheadline)
        }
    }

    @ViewBuilder
    private func sourceLink(_ options: [SourceOption]) -> some View {
        if sourceKey.isEmpty {
            Text("选择数据源后可直接浏览该来源的推荐内容")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            NavigationLink {
                DiscoverProviderView(sourceKey: sourceKey,
                                     title: options.first { $0.id == sourceKey }?.name ?? sourceKey)
            } label: {
                Label("浏览该数据源", systemImage: "arrow.right.circle")
            }
        }
    }

    // MARK: - 筛选

    @ViewBuilder
    private func filterCard(_ genres: JSONValue) -> some View {
        let options = discoverGenreOptions(genres)
        CardSection(title: "筛选", systemImage: "line.3.horizontal.decrease.circle") {
            VStack(alignment: .leading, spacing: 10) {
                Picker("方式", selection: $mode) {
                    ForEach(BrowseMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: mode) { _, _ in resetPage() }

                Picker("媒体类型", selection: $mediaType) {
                    Text("电影").tag("movie")
                    Text("剧集").tag("tv")
                }
                .pickerStyle(.segmented)
                .onChange(of: mediaType) { _, _ in resetPage() }

                Picker("类型", selection: $genreID) {
                    Text(mode == .genre ? "请选择类型" : "全部类型").tag(0)
                    ForEach(options) { Text($0.name).tag($0.id) }
                }
                .pickerStyle(.menu)
                .onChange(of: genreID) { _, _ in resetPage() }

                if mode == .tmdb { tmdbFilters }

                Text("类型列表来自 /api/discover/genres（服务端缓存 24 小时），共 \(options.count) 项")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }

    private var tmdbFilters: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("排序", selection: $sortBy) {
                Text("按热度").tag("popularity.desc")
                Text("按评分").tag("vote_average.desc")
                Text("按评价人数").tag("vote_count.desc")
            }
            .pickerStyle(.menu)
            .onChange(of: sortBy) { _, _ in resetPage() }

            Picker("原始语言", selection: $language) {
                Text("不限").tag("")
                Text("中文").tag("zh")
                Text("英语").tag("en")
                Text("日语").tag("ja")
                Text("韩语").tag("ko")
            }
            .pickerStyle(.menu)
            .onChange(of: language) { _, _ in resetPage() }

            Picker("最低评分", selection: $minRating) {
                Text("不限").tag(0.0)
                Text("6 分以上").tag(6.0)
                Text("7 分以上").tag(7.0)
                Text("8 分以上").tag(8.0)
            }
            .pickerStyle(.menu)
            .onChange(of: minRating) { _, _ in resetPage() }
        }
    }

    // MARK: - 结果

    @ViewBuilder
    private func resultCard(_ results: JSONValue) -> some View {
        let items = mediaItemList(results)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(mode == .genre ? "按类型浏览" : "TMDb 发现")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                StatusBadge("第 \(page) 页", tone: .info)
                StatusBadge("\(items.count) 条", tone: items.isEmpty ? .neutral : .good)
            }
            if mode == .genre, genreID == 0 {
                Text("请先在上方选择一个类型")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            } else {
                PosterGrid(items: items)
            }
            pageBar(hasMore: !items.isEmpty)
        }
    }

    private func pageBar(hasMore: Bool) -> some View {
        HStack {
            Button("上一页") {
                guard page > 1 else { return }
                page -= 1
                queryKey += 1
            }
            .buttonStyle(.borderless)
            .disabled(page <= 1)
            Spacer()
            Button("下一页") {
                page += 1
                queryKey += 1
            }
            .buttonStyle(.borderless)
            .disabled(!hasMore)
        }
        .font(.subheadline)
    }

    // MARK: - 工具

    private var toolCard: some View {
        CardSection(title: "工具", systemImage: "wrench.and.screwdriver") {
            VStack(alignment: .leading, spacing: 12) {
                NavigationLink {
                    DoubanResolveView()
                } label: {
                    Label("豆瓣 → TMDb 匹配", systemImage: "arrow.triangle.2.circlepath")
                }
                NavigationLink {
                    TmdbArtworkBatchView()
                } label: {
                    Label("批量获取 TMDb 海报", systemImage: "photo.on.rectangle.angled")
                }
                NavigationLink {
                    SSEStreamView(title: "发现实时事件",
                                  note: "服务端在刷新缓存、抓取数据源时会推送事件，页面停留期间保持长连接。") {
                        try $0.discover.discoverRealtimeEventsRequest()
                    }
                } label: {
                    Label("实时事件", systemImage: "dot.radiowaves.left.and.right")
                }
            }
            .font(.subheadline)
        }
    }

}

/// 单个发现数据源的推荐结果：`/api/discover/provider/{source_key}`。
struct DiscoverProviderView: View {
    let sourceKey: String
    let title: String

    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteScroll(title: title) {
            let api = try session.requireAPI()
            return try await api.discover.discoverProvider(sourceKey: sourceKey)
        } content: { value, _ in
            let items = mediaItemList(value)
            CardSection(title: "来源信息", systemImage: "info.circle") {
                VStack(spacing: 8) {
                    KeyValueRow("source_key", sourceKey, monospaced: true)
                    KeyValueRow("条目数", "\(items.count)")
                    if let name = value.first(of: "name", "title", "source_name").displayString {
                        KeyValueRow("名称", name)
                    }
                    if let updated = value.first(of: "updated_at", "cached_at", "time").displayString {
                        KeyValueRow("更新时间", Fmt.relative(.string(updated)))
                    }
                }
                .font(.subheadline)
            }
            PosterGrid(items: items)
        }
    }
}

/// 豆瓣 → TMDb 匹配：`POST /api/discover/resolve_tmdb`。
struct DoubanResolveView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    @State private var name = ""
    @State private var year = ""
    @State private var mediaType = "movie"
    @State private var requestBody: JSONValue = .null

    var body: some View {
        Form {
            Section {
                TextField("标题", text: $name)
                TextField("年份（可空）", text: $year)
                    .keyboardType(.numberPad)
                Picker("类型", selection: $mediaType) {
                    Text("电影").tag("movie")
                    Text("剧集").tag("tv")
                }
            } header: {
                Text("待匹配条目")
            } footer: {
                Text("接口按「标题 + 年份 + 类型」批量匹配，不接受豆瓣 ID 或链接，因此这里填写豆瓣条目的标题与年份。")
            }

            Section {
                Button {
                    resolve()
                } label: {
                    Label("匹配 TMDb", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            resultSection
        }
        .navigationTitle("豆瓣 → TMDb 匹配")
        .actionFeedback(runner)
    }

    @ViewBuilder
    private var resultSection: some View {
        if !runner.lastResult.isNull {
            Section("匹配结果") {
                if resolvedPairs.isEmpty {
                    EmptyRow("没有匹配到 TMDb ID")
                }
                ForEach(resolvedPairs, id: \.key) { pair in
                    KeyValueRow(pair.key, Fmt.text(pair.value))
                }
                if let id = firstResolvedID {
                    NavigationLink {
                        MediaDetailView(summary: MediaSummary(.object([
                            "id": .int(id),
                            "title": .string(name),
                            "media_type": .string(mediaType),
                            "year": .string(year),
                        ])))
                    } label: {
                        Label("查看 TMDB \(id) 详情", systemImage: "film")
                    }
                }
                JSONInspector(value: runner.lastResult, title: "匹配响应")
            }
        }
#if DEBUG
        if !requestBody.isNull {
            Section("调试") {
                JSONInspector(value: requestBody, title: "请求体")
            }
        }
#endif
    }

    private var resolvedPairs: [(key: String, value: JSONValue)] {
        let results = runner.lastResult["results"]
        if !results.isNull { return results.sortedPairs }
        return runner.lastResult.sortedPairs.filter { $0.key != "success" }
    }

    private var firstResolvedID: Int? {
        for pair in resolvedPairs {
            if let id = pair.value.int, id > 0 { return id }
        }
        return runner.lastResult.deepFirst(of: "tmdb_id", "tmdbid").int
    }

    private func resolve() {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedYear = year.trimmingCharacters(in: .whitespacesAndNewlines)
        var item: [String: JSONValue] = ["title": .string(title), "media_type": .string(mediaType)]
        if !trimmedYear.isEmpty { item["year"] = .string(trimmedYear) }
        let body = JSONValue.array([.object(item)])
        requestBody = body
        runner.run(nil) {
            let api = try session.requireAPI()
            return try await api.discover.resolveDoubanToTmdb(body)
        }
    }
}

/// 批量获取 TMDb 海报：`/api/discover/tmdb_artwork/batch`。
/// 该接口请求体在 OpenAPI 中是自由对象，这里按 `items` + `tmdb_ids` 两种常见写法同时提交，
/// 并把实际提交的请求体展示出来，便于与服务端日志比对。
struct TmdbArtworkBatchView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    @State private var idsText = ""
    @State private var mediaType = "movie"
    @State private var requestBody: JSONValue = .null

    var body: some View {
        Form {
            Section {
                TextField("TMDb ID（逗号分隔）", text: $idsText)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                Picker("类型", selection: $mediaType) {
                    Text("电影").tag("movie")
                    Text("剧集").tag("tv")
                }
                .pickerStyle(.segmented)
                Button("批量获取") { submit() }
                    .disabled(runner.isRunning || parsedIDs.isEmpty)
            } header: {
                Text("参数")
            } footer: {
                Text("识别到 \(parsedIDs.count) 个 ID，将按服务端批量接口提交。")
            }

            resultSection

#if DEBUG
            if !requestBody.isNull {
                Section("调试") {
                    JSONInspector(value: requestBody, title: "请求体")
                }
            }
#endif
        }
        .navigationTitle("批量海报")
        .actionFeedback(runner)
    }

    @ViewBuilder
    private var resultSection: some View {
        let items = resultItems
        if !items.isEmpty {
            Section("结果（\(items.count)）") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, pair in
                            PosterCard(title: pair.value.first(of: "title", "name").displayString ?? pair.key,
                                       subtitle: pair.value.first(of: "media_type", "type").displayString,
                                       badge: "#\(index + 1)",
                                       url: artworkURL(pair.value),
                                       width: 132)
                        }
                    }
                    .padding(.vertical, 4)
                }
                JSONInspector(value: runner.lastResult, title: "响应原始数据")
            }
        }
    }

    /// 响应既可能是数组，也可能是以 tmdb_id 为键的字典。
    private var resultItems: [(key: String, value: JSONValue)] {
        let list = runner.lastResult.list("items", "results", "data", "artworks")
        if !list.isEmpty {
            return list.enumerated().map { (String($0.offset + 1), $0.element) }
        }
        let node = runner.lastResult["results"].isNull ? runner.lastResult : runner.lastResult["results"]
        return node.sortedPairs.filter { $0.value.object != nil || $0.value.array != nil }
    }

    private func artworkURL(_ item: JSONValue) -> URL? {
        let api = session.api
        if let path = item.first(of: "poster_path", "posterPath", "backdrop_path", "file_path").string,
           path.hasPrefix("/") {
            return try? api?.discover.tmdbImageProxyURL(path: path)
        }
        if let first = item.array?.first,
           let path = first.first(of: "file_path", "poster_path", "backdrop_path").string,
           path.hasPrefix("/") {
            return try? api?.discover.tmdbImageProxyURL(path: path)
        }
        return Artwork.url(for: item, api: api, session: session)
    }

    private var parsedIDs: [Int] {
        idsText.split(whereSeparator: { ",，、; \n\t ".contains($0) })
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }

    private func submit() {
        let ids = parsedIDs
        guard !ids.isEmpty else { return }
        let numbers = ids.map { JSONValue.int($0) }
        let objects = ids.map { JSONValue.object(["tmdb_id": .int($0), "media_type": .string(mediaType)]) }
        let body = JSONValue.object(["items": .array(objects),
                                     "tmdb_ids": .array(numbers),
                                     "media_type": .string(mediaType)])
        requestBody = body
        runner.run(nil) {
            let api = try session.requireAPI()
            return try await api.discover.tmdbArtworkBatch(body)
        }
    }
}

/// 删除 Emby 剧集条目：`/api/discover/emby/items/delete`。
/// 破坏性操作，走二次确认；请求体同样是自由对象，按 `item_ids` + `ids` 同时提交。
struct EmbyItemsDeleteView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    @State private var idsText = ""
    @State private var confirming = false
    @State private var requestBody: JSONValue = .null

    var body: some View {
        Form {
            Section {
                TextEditor(text: $idsText)
                    .frame(minHeight: 96)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("条目 ID")
            } footer: {
                Text("逗号或换行分隔，识别到 \(parsedIDs.count) 个 ID。删除后无法在 App 内撤销。")
            }

            Section {
                Button(role: .destructive) {
                    confirming = true
                } label: {
                    Label("删除这些条目", systemImage: "trash")
                }
                .disabled(runner.isRunning || parsedIDs.isEmpty)
            }

            if !runner.lastResult.isNull {
                Section("结果") {
                    JSONFieldList(value: runner.lastResult)
                    JSONInspector(value: runner.lastResult, title: "响应原始数据")
                }
            }

#if DEBUG
            if !requestBody.isNull {
                Section("调试") {
                    JSONInspector(value: requestBody, title: "请求体")
                }
            }
#endif
        }
        .navigationTitle("删除 Emby 条目")
        .confirmationDialog("确认删除 \(parsedIDs.count) 个 Emby 条目？",
                            isPresented: $confirming,
                            titleVisibility: .visible) {
            Button("删除", role: .destructive) { submit() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作会直接调用 Emby 删除接口，媒体文件是否一并删除取决于服务端配置。")
        }
        .actionFeedback(runner)
    }

    private var parsedIDs: [String] {
        idsText.split(whereSeparator: { ",，、; \n\t ".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func submit() {
        let ids = parsedIDs
        guard !ids.isEmpty else { return }
        let values = ids.map { JSONValue.string($0) }
        let body = JSONValue.object(["item_ids": .array(values), "ids": .array(values)])
        requestBody = body
        runner.run("已提交删除") {
            let api = try session.requireAPI()
            return try await api.discover.deleteEmbySeriesItems(body)
        }
    }
}
