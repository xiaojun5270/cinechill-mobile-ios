import SwiftUI
import UIKit

/// RSS 全局配置：源目录与硬链目录。
struct RSSConfigView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var sourceRoot = ""
    @State private var linkRoot = ""
    @State private var loaded = false

    var body: some View {
        Form {
            Section("目录") {
                TextField("源目录", text: $sourceRoot)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("硬链目录", text: $linkRoot)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Section {
                Button("保存") {
                    runner.run("已保存") {
                        let api = try session.requireAPI()
                        return try await api.rss.saveRssConfig(
                            RssGlobalConfig(sourceRoot: sourceRoot, linkRoot: linkRoot))
                    }
                }
                .disabled(sourceRoot.isEmpty || linkRoot.isEmpty)
            } footer: {
                Text("RSS 命中的条目会从源目录硬链到硬链目录，两者需在同一文件系统内。")
            }
        }
        .navigationTitle("RSS 全局配置")
        .actionFeedback(runner)
        .task {
            guard !loaded, let api = session.api else { return }
            loaded = true
            let config = await Probe.json { try await api.rss.getRssConfig() }
            sourceRoot = config.deepFirst(of: "source_root", "sourceRoot").string ?? ""
            linkRoot = config.deepFirst(of: "link_root", "linkRoot").string ?? ""
        }
    }
}

/// 链接生成器：按服务端预设填参数并生成 RSS 地址。
struct RSSPresetsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "链接生成器", subtitle: "预设来自服务端 /api/rss/link-presets") {
            let api = try session.requireAPI()
            return try await api.rss.getRssLinkPresets()
        } content: { value, _ in
            let presets = value.list("presets", "items")
            if presets.isEmpty { Section { JSONFieldList(value: value) } }
            ForEach(Array(presets.enumerated()), id: \.offset) { _, preset in
                NavigationLink {
                    RSSPresetBuilderView(preset: preset)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(preset.first(of: "name", "title", "label").displayString ?? "—")
                        if let id = preset.first(of: "id", "preset_id", "key").displayString {
                            Text(id).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section {
                NavigationLink {
                    RSSBuiltinFeedsView()
                } label: {
                    Label("内置榜单直连", systemImage: "list.star")
                }
            }
        }
    }
}

/// 单个预设的参数填写与地址生成。
struct RSSPresetBuilderView: View {
    let preset: JSONValue

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var params: JSONValue = .object([:])
    @State private var useProxy = true
    @State private var prepared = false

    private var presetID: String {
        preset.first(of: "id", "preset_id", "key").displayString ?? ""
    }

    var body: some View {
        Form {
            if let note = preset.first(of: "description", "note", "hint").displayString {
                Section { Text(note).font(.footnote).foregroundStyle(.secondary) }
            }
            Section("参数") {
                if params.isEmptyContainer {
                    Text("该预设无需参数").font(.footnote).foregroundStyle(.secondary)
                } else {
                    JSONObjectEditor(value: $params)
                }
            }
            Section {
                Toggle("通过服务端代理访问", isOn: $useProxy)
                Button {
                    runner.run(nil) {
                        let api = try session.requireAPI()
                        return try await api.rss.buildRssUrl(
                            RssBuildUrlRequest(presetId: presetID, params: params, proxy: useProxy))
                    }
                } label: {
                    Label("生成地址", systemImage: "wand.and.stars")
                }
                .disabled(presetID.isEmpty)
            }
            if let url = runner.lastResult.deepFirst(of: "url", "rss_url", "link").displayString {
                Section("生成结果") {
                    Text(url)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                    Button {
                        UIPasteboard.general.string = url
                    } label: {
                        Label("复制地址", systemImage: "doc.on.doc")
                    }
                }
            }
        }
        .navigationTitle(preset.first(of: "name", "title").displayString ?? "预设")
        .actionFeedback(runner)
        .task {
            guard !prepared else { return }
            prepared = true
            params = defaultParams()
        }
    }

    /// 预设可能给出 `params`（默认值对象）或 `fields`（字段声明数组）。
    private func defaultParams() -> JSONValue {
        if let object = preset.deepFirst(of: "params", "default_params", "defaults").object {
            return .object(object)
        }
        let fields = preset.deepFirst(of: "fields", "options", "schema").array ?? []
        var result: [String: JSONValue] = [:]
        for field in fields {
            guard let key = field.first(of: "key", "name", "id").string else { continue }
            let fallback = field.first(of: "default", "value", "placeholder")
            result[key] = fallback.isNull ? .string("") : fallback
        }
        return .object(result)
    }
}

/// 任意 RSS 地址预览。
struct RSSPreviewView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var url = ""
    @State private var contentType = "movies"
    @State private var limit = 10

    var body: some View {
        Form {
            Section("输入") {
                TextField("RSS 地址", text: $url, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Picker("内容类型", selection: $contentType) {
                    Text("电影").tag("movies")
                    Text("剧集").tag("tv")
                }
                Stepper("预览条数 \(limit)", value: $limit, in: 1...50)
            }
            Section {
                Button("解析预览") {
                    runner.run(nil) {
                        let api = try session.requireAPI()
                        return try await api.rss.previewRssUrl(
                            RssPreviewRequest(rssUrl: url, contentType: contentType, limit: limit))
                    }
                }
                .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            let items = runner.lastResult.list("items", "entries", "results")
            if !items.isEmpty {
                Section("解析结果") {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 10) {
                            RemoteImage(url: Self.posterURL(item, session: session), placeholderIcon: "film")
                                .frame(width: 40, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.first(of: "title", "name").displayString ?? "—")
                                    .font(.subheadline)
                                HStack(spacing: 8) {
                                    if let year = item.first(of: "year").displayString {
                                        Text(year)
                                    }
                                    if let tmdb = item.deepFirst(of: "tmdb_id", "tmdbid").displayString {
                                        Text("TMDB " + tmdb)
                                    }
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("订阅预览")
        .actionFeedback(runner)
    }

    /// RSS 源里的图片多是外链，统一走服务端的 `/api/rss/image_proxy` 以免被防盗链拦掉。
    static func posterURL(_ item: JSONValue, session: AppSession) -> URL? {
        guard let raw = item.first(of: "poster", "image", "cover", "thumbnail", "poster_path").displayString,
              !raw.isEmpty else { return nil }
        if raw.hasPrefix("http") {
            return (try? session.api?.rss.rssImageProxyURL(url: raw)) ?? URL(string: raw)
        }
        return session.absoluteURL(raw)
    }
}
