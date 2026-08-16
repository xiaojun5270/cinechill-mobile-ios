import SwiftUI
import UIKit

/// 资源转发（Aiying）：配置、Widget Token、资源搜索与转存。
struct ForwardView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var enabled = true
    @State private var publicBase = ""
    @State private var libraryEnabled = true
    @State private var transferMode = "series"
    @State private var aiyingEnabled = false
    @State private var aiyingTgID = ""
    @State private var aiyingToken = ""

    var body: some View {
        RemoteList(title: "资源转发") {
            let api = try session.requireAPI()
            async let configRequest = Probe.json { try await api.forward.getConfig() }
            async let sourcesRequest = Probe.json { try await api.forward.getSearchSources() }
            let (config, sources) = await (configRequest, sourcesRequest)
            return JSONValue.object(["config": config, "sources": sources])
        } content: { value, reload in
            let widgetToken = value["config"].deepFirst(of: "widget_token", "token").displayString ?? ""
            Section("基础配置") {
                Toggle("启用转发", isOn: $enabled)
                TextField("对外访问地址", text: $publicBase)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Toggle("媒体库入口", isOn: $libraryEnabled)
                Picker("转存模式", selection: $transferMode) {
                    Text("按剧集").tag("series")
                    Text("按文件").tag("file")
                }
            }
            Section("Aiying") {
                Toggle("启用 Aiying", isOn: $aiyingEnabled)
                TextField("Telegram ID", text: $aiyingTgID)
                    .textInputAutocapitalization(.never)
                SecureField("Chill Token", text: $aiyingToken)
            }
            Section {
                Button {
                    runner.run("已保存", operation: {
                        let api = try session.requireAPI()
                        return try await api.forward.saveConfig(
                            ForwardConfigRequest(enabled: enabled, publicBaseUrl: publicBase,
                                                 libraryEnabled: libraryEnabled,
                                                 transferMode: transferMode,
                                                 aiyingEnabled: aiyingEnabled,
                                                 aiyingTgId: aiyingTgID,
                                                 aiyingChillToken: aiyingToken))
                    }, onSuccess: { await reload() })
                } label: {
                    Label("保存配置", systemImage: "square.and.arrow.down")
                }
                Button {
                    runner.run("已刷新 Token", operation: {
                        let api = try session.requireAPI()
                        return try await api.forward.refreshWidgetToken()
                    }, onSuccess: { await reload() })
                } label: {
                    Label("刷新 Widget Token", systemImage: "arrow.triangle.2.circlepath")
                }
                if !widgetToken.isEmpty {
                    HStack {
                        Text(widgetToken)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(1)
                            .textSelection(.enabled)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = widgetToken
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                    }
                    widgetScriptRow(token: widgetToken)
                }
            }

            let sources = value["sources"].list("sources", "items")
            Section("搜索源（\(sources.count)）") {
                if sources.isEmpty { EmptyRow("没有可用搜索源") }
                ForEach(Array(sources.enumerated()), id: \.offset) { _, source in
                    HStack {
                        Text(source.first(of: "name", "label", "id").displayString ?? "—")
                        Spacer()
                        if let key = source.first(of: "id", "key").displayString {
                            Text(key).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section {
                NavigationLink {
                    ForwardSearchView()
                } label: {
                    Label("资源搜索与转存", systemImage: "magnifyingglass")
                }
                NavigationLink {
                    ForwardResourcesView(initialToken: widgetToken)
                } label: {
                    Label("已转发资源", systemImage: "square.stack.3d.up")
                }
                JSONInspector(value: value)
            }
            .task { apply(value["config"]) }
        }
        .actionFeedback(runner)
    }

    /// Widget 嵌入脚本地址：`/api/forward/widget.js?token=…`，贴到网页里即可加载转发组件。
    @ViewBuilder
    private func widgetScriptRow(token: String) -> some View {
        let url = try? session.api?.forward.widgetJsURL(token: token)
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("嵌入脚本").font(.caption).foregroundStyle(.secondary)
                Text(url?.absoluteString ?? "—")
                    .font(.system(.caption2, design: .monospaced))
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
            Spacer()
            Button {
                UIPasteboard.general.string = url?.absoluteString ?? ""
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .disabled(url == nil)
        }
    }

    private func apply(_ config: JSONValue) {        enabled = config.deepFirst(of: "enabled").bool ?? enabled
        publicBase = config.deepFirst(of: "public_base_url").string ?? publicBase
        libraryEnabled = config.deepFirst(of: "library_enabled").bool ?? libraryEnabled
        transferMode = config.deepFirst(of: "transfer_mode").string ?? transferMode
        aiyingEnabled = config.deepFirst(of: "aiying_enabled").bool ?? aiyingEnabled
        aiyingTgID = config.deepFirst(of: "aiying_tg_id").displayString ?? aiyingTgID
    }
}

/// 转发资源搜索：按 TMDB / 标题搜索，可预览、转存、下载。
struct ForwardSearchView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var type = "movie"
    @State private var tmdbID = ""
    @State private var title = ""
    @State private var year = ""
    @State private var season = ""
    @State private var episode = ""

    private var seasonValue: Int? { Int(season) }
    private var episodeValue: Int? { Int(episode) }

    var body: some View {
        Form {
            Section("条件") {
                Picker("类型", selection: $type) {
                    Text("电影").tag("movie")
                    Text("剧集").tag("tv")
                }
                TextField("TMDB ID", text: $tmdbID)
                    .textInputAutocapitalization(.never)
                TextField("标题", text: $title)
                TextField("年份", text: $year)
                    .textInputAutocapitalization(.never)
                if type == "tv" {
                    TextField("季", text: $season).textInputAutocapitalization(.never)
                    TextField("集", text: $episode).textInputAutocapitalization(.never)
                }
            }
            Section {
                Button("搜索资源") {
                    runner.run(nil) {
                        let api = try session.requireAPI()
                        return try await api.forward.searchForwardResources(
                            ResourceSearchRequest(typeValue: type, tmdbId: tmdbID, title: title,
                                                  year: year, season: seasonValue,
                                                  episode: episodeValue, sources: nil))
                    }
                }
                .disabled(tmdbID.isEmpty && title.isEmpty)
                Button("测试可用性") {
                    runner.run(nil) {
                        let api = try session.requireAPI()
                        return try await api.forward.testResources(
                            ResourceTestRequest(typeValue: type, tmdbId: tmdbID))
                    }
                }
                .disabled(tmdbID.isEmpty)
                NavigationLink {
                    SSEStreamView(title: "流式搜索",
                                  note: "各资源站返回速度不一，流式接口会边搜边推，比一次性返回更快看到结果。") {
                        try $0.forward.streamForwardResourcesRequest(
                            ResourceSearchRequest(typeValue: type, tmdbId: tmdbID, title: title,
                                                  year: year, season: seasonValue,
                                                  episode: episodeValue, sources: nil))
                    }
                } label: {
                    Label("流式搜索（SSE）", systemImage: "dot.radiowaves.left.and.right")
                }
                .disabled(tmdbID.isEmpty && title.isEmpty)
            }

            let results = runner.lastResult.list("results", "items", "resources")
            if !results.isEmpty {
                Section("结果（\(results.count)）") {
                    ForEach(Array(results.enumerated()), id: \.offset) { _, item in
                        resultRow(item)
                    }
                }
            }
        }
        .navigationTitle("资源搜索")
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func resultRow(_ item: JSONValue) -> some View {
        let source = item.first(of: "source").string ?? "aiying"
        let resourceID = item.first(of: "resource_id", "id").displayString ?? ""
        VStack(alignment: .leading, spacing: 4) {
            Text(item.first(of: "title", "name").displayString ?? "—")
                .font(.subheadline)
                .lineLimit(2)
            HStack(spacing: 8) {
                Text(source)
                if let size = item.first(of: "size", "size_text").displayString { Text("· " + size) }
                if let quality = item.first(of: "quality", "resolution").displayString { Text("· " + quality) }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            if !resourceID.isEmpty {
                HStack(spacing: 14) {
                    Button("预览") {
                        runner.run(nil) {
                            let api = try session.requireAPI()
                            return try await api.forward.previewForwardResource(
                                ResourcePreviewRequest(source: source, resourceId: resourceID,
                                                       typeValue: type, tmdbId: tmdbID, title: title,
                                                       year: year, season: seasonValue,
                                                       episode: episodeValue))
                        }
                    }
                    Button("转存") {
                        runner.run("已提交转存") {
                            let api = try session.requireAPI()
                            return try await api.forward.transferForwardResource(
                                ResourceTransferRequest(source: source, resourceId: resourceID,
                                                        typeValue: type, tmdbId: tmdbID, title: title,
                                                        year: year, season: seasonValue,
                                                        episode: episodeValue))
                        }
                    }
                    Button("下载") {
                        runner.run("已提交下载") {
                            let api = try session.requireAPI()
                            return try await api.forward.downloadForwardResource(
                                ResourceDownloadRequest(source: source, resourceId: resourceID,
                                                        typeValue: type, tmdbId: tmdbID, title: title,
                                                        year: year, season: seasonValue,
                                                        episode: episodeValue, fillMode: "full",
                                                        existingEpisodesBySeason: nil))
                        }
                    }
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
        }
    }
}

/// 已转发资源列表：`POST /api/forward/resources`，可用 Widget Token 以外部身份查看。
struct ForwardResourcesView: View {
    @EnvironmentObject private var session: AppSession
    let initialToken: String
    @State private var tokenInput = ""
    @State private var queryKey = 0

    private var effectiveToken: String {
        let typed = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return typed.isEmpty ? initialToken : typed
    }

    var body: some View {
        RemoteList(title: "已转发资源", cacheKey: "forward-resources-\(queryKey)") {
            let api = try session.requireAPI()
            let token = effectiveToken
            return try await api.forward.loadForwardResources(token: token.isEmpty ? nil : token)
        } content: { value, _ in
            tokenSection
            let resources = value.list("resources", "items", "data")
            Section("资源（\(resources.count)）") {
                if resources.isEmpty {
                    EmptyRow("暂无转发资源")
                    JSONFieldList(value: value, skipKeys: ["resources", "items", "data"])
                }
                ForEach(Array(resources.enumerated()), id: \.offset) { _, item in
                    NavigationLink {
                        ForwardResourceDetailView(resource: item, token: effectiveToken)
                    } label: {
                        resourceRow(item)
                    }
                }
            }
            Section {
                JSONInspector(value: value)
            }
        }
        .id(queryKey)
    }

    @ViewBuilder
    private var tokenSection: some View {
        Section {
            TextField("Widget Token（留空用配置里的）", text: $tokenInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button {
                queryKey += 1
            } label: {
                Label("按该 Token 重新加载", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("Token")
        } footer: {
            Text(effectiveToken.isEmpty
                 ? "未携带 token，将以当前登录会话请求。"
                 : "已携带 token（\(effectiveToken.count) 位）。")
        }
    }

    @ViewBuilder
    private func resourceRow(_ item: JSONValue) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.first(of: "title", "name", "resource_id", "id").displayString ?? "—")
                .font(.subheadline)
                .lineLimit(2)
            HStack(spacing: 8) {
                if let source = item.first(of: "source", "provider").displayString {
                    Text(source)
                }
                if let type = item.first(of: "type", "media_type").displayString {
                    Text("· " + type)
                }
                if let size = item.first(of: "size", "size_text", "file_size").displayString {
                    Text("· " + size)
                }
                if let status = item.first(of: "status", "state").displayString {
                    Text("· " + status)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}
/// 单个转发资源：下载/转存到网盘，并取得可复制、可分享的播放地址。
struct ForwardResourceDetailView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    let resource: JSONValue
    let token: String

    @State private var source = "aiying"
    @State private var resourceID = ""
    @State private var type = "movie"
    @State private var tmdbID = ""
    @State private var title = ""
    @State private var year = ""
    @State private var season = ""
    @State private var episode = ""
    @State private var fillMode = "full"
    @State private var ignoreEnabled = false
    @State private var prepared = false

    private var seasonValue: Int? { Int(season) }
    private var episodeValue: Int? { Int(episode) }

    /// 播放地址由生成的 URL 构造器拼装，不手写查询串。
    private var playURL: URL? {
        guard let api = session.api else { return nil }
        return try? api.forward.playForwardResourceURL(
            token: token.isEmpty ? nil : token,
            source: source,
            resourceId: resourceID.isEmpty ? nil : resourceID,
            type: type,
            tmdbId: tmdbID.isEmpty ? nil : tmdbID,
            season: seasonValue,
            episode: episodeValue,
            ignoreEnabled: ignoreEnabled)
    }

    var body: some View {
        Form {
            infoSection
            paramsSection
            actionSection
            playSection
            Section {
                JSONInspector(value: resource, title: "资源原始数据")
            }
        }
        .navigationTitle(resource.first(of: "title", "name").displayString ?? "转发资源")
        .actionFeedback(runner)
        .task {
            guard !prepared else { return }
            prepared = true
            apply()
        }
    }
    @ViewBuilder
    private var infoSection: some View {
        Section("资源") {
            KeyValueRow("来源", source)
            KeyValueRow("资源 ID", resourceID.isEmpty ? "—" : resourceID, monospaced: true)
            if let size = resource.first(of: "size", "size_text", "file_size").displayString {
                KeyValueRow("大小", size)
            }
            if let status = resource.first(of: "status", "state").displayString {
                HStack {
                    Text("状态").foregroundStyle(.secondary)
                    Spacer()
                    StatusBadge(status, tone: badgeTone(for: status))
                }
            }
        }
    }

    @ViewBuilder
    private var paramsSection: some View {
        Section {
            Picker("类型", selection: $type) {
                Text("电影").tag("movie")
                Text("剧集").tag("tv")
            }
            TextField("TMDB ID", text: $tmdbID)
                .textInputAutocapitalization(.never)
            TextField("标题", text: $title)
            TextField("年份", text: $year)
                .textInputAutocapitalization(.never)
            if type == "tv" {
                TextField("季", text: $season).textInputAutocapitalization(.never)
                TextField("集", text: $episode).textInputAutocapitalization(.never)
            }
            TextField("补全模式 fill_mode", text: $fillMode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } header: {
            Text("下载参数")
        } footer: {
            Text("对应 POST /api/forward/download_resource；fill_mode 服务端默认 full，existing_episodes_by_season 不提交。")
        }
    }
    @ViewBuilder
    private var actionSection: some View {
        Section {
            Button {
                runner.run("已提交下载") {
                    let api = try session.requireAPI()
                    return try await api.forward.downloadForwardResource(
                        ResourceDownloadRequest(source: source, resourceId: resourceID,
                                                typeValue: type, tmdbId: tmdbID, title: title,
                                                year: year, season: seasonValue,
                                                episode: episodeValue, fillMode: fillMode,
                                                existingEpisodesBySeason: nil))
                }
            } label: {
                Label("下载 / 转存该资源", systemImage: "arrow.down.circle")
            }
            .disabled(resourceID.isEmpty)
            if !runner.lastResult.isNull {
                JSONInspector(value: runner.lastResult, title: "最近一次响应")
            }
        }
    }

    @ViewBuilder
    private var playSection: some View {
        Section {
            Toggle("忽略启用开关 ignore_enabled", isOn: $ignoreEnabled)
            if let url = playURL {
                Text(url.absoluteString)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                Button {
                    UIPasteboard.general.string = url.absoluteString
                } label: {
                    Label("复制播放地址", systemImage: "doc.on.doc")
                }
                ShareLink(item: url) {
                    Label("分享播放地址", systemImage: "square.and.arrow.up")
                }
                Link(destination: url) {
                    Label("在浏览器打开", systemImage: "safari")
                }
            } else {
                EmptyRow("尚未选择服务器，无法生成播放地址")
            }
        } header: {
            Text("播放地址")
        } footer: {
            Text(token.isEmpty
                 ? "GET /api/forward/play；未附带 Widget Token，外部访问可能被拒绝。"
                 : "GET /api/forward/play；已附带 Widget Token。")
        }
    }
    private func apply() {
        source = resource.first(of: "source", "provider").string ?? source
        resourceID = resource.first(of: "resource_id", "id", "resourceId").displayString ?? resourceID
        if let raw = resource.first(of: "type", "media_type").string?.lowercased() {
            let isSeries = raw.contains("tv") || raw.contains("series") || raw.contains("show") || raw.contains("剧")
            type = isSeries ? "tv" : "movie"
        }
        tmdbID = resource.first(of: "tmdb_id", "tmdbId").displayString ?? tmdbID
        title = resource.first(of: "title", "name").displayString ?? title
        year = resource.first(of: "year", "release_year").displayString ?? year
        if let value = resource.first(of: "season", "season_number").int { season = String(value) }
        if let value = resource.first(of: "episode", "episode_number").int { episode = String(value) }
    }
}
