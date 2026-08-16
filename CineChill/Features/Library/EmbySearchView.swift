import SwiftUI

/// Emby 搜索：检索媒体服务器条目，并按 Web 端流程加载条目图片。
struct EmbySearchView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    @State private var keyword = ""
    @State private var libraryID = ""
    @State private var results: [JSONValue] = []
    @State private var searched = false

    var body: some View {
        Form {
            Section("检索条件") {
                TextField("关键词", text: $keyword)
                    .submitLabel(.search)
                    .onSubmit { search() }
                TextField("媒体库 ID（可留空）", text: $libraryID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("搜索") { search() }
                    .disabled(runner.isRunning || keyword.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            resultsSection
        }
        .navigationTitle("Emby 搜索")
        .actionFeedback(runner)
    }

    @ViewBuilder
    private var resultsSection: some View {
        if results.isEmpty {
            if searched && !runner.isRunning {
                Section { EmptyRow("没有匹配的条目") }
            }
        } else {
            Section("结果（\(results.count)）") {
                ForEach(Array(results.enumerated()), id: \.offset) { index, item in
                    NavigationLink {
                        EmbySearchResultDetailView(item: item, fallbackTitle: "条目 \(index + 1)")
                    } label: {
                        row(item, index: index)
                    }
                }
            }
            Section { JSONInspector(value: .array(results), title: "搜索结果原始数据") }
        }
    }

    @ViewBuilder
    private func row(_ item: JSONValue, index: Int) -> some View {
        HStack(spacing: 12) {
            RemoteImage(url: searchArtworkURL(item), placeholderIcon: "film")
                .frame(width: 44, height: 62)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title(item) ?? "条目 \(index + 1)").font(.subheadline)
                HStack(spacing: 6) {
                    if let type = item.first(of: "type", "Type", "media_type").displayString {
                        StatusBadge(type, tone: badgeTone(for: type))
                    }
                    if let year = item.first(of: "year", "ProductionYear", "premiere_year").displayString {
                        Text(year).font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let path = item.first(of: "path", "Path", "library").displayString {
                    Text(path).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
        }
    }

    private func title(_ item: JSONValue) -> String? {
        item.first(of: "name", "Name", "title", "Title", "original_title").displayString
    }

    private func searchArtworkURL(_ item: JSONValue) -> URL? {
        embyArtworkURL(item, api: session.api, session: session)
    }

    private func search() {
        let query = keyword.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        let library = libraryID.trimmingCharacters(in: .whitespaces)
        runner.run(nil, operation: {
            let api = try session.requireAPI()
            let connection = try await EmbyConnection.require(api: api)
            return try await api.server.embySearch(
                EmbySearchRequest(url: connection.url,
                                  key: connection.key,
                                  publicHost: connection.publicHost,
                                  query: query,
                                  libraryId: library.isEmpty ? nil : library))
        }, onSuccess: {
            results = runner.lastResult.list("items", "results", "data", "Items")
            searched = true
        })
    }
}

private struct EmbySearchResultDetailView: View {
    let item: JSONValue
    let fallbackTitle: String

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var images: [JSONValue] = []

    private var title: String {
        item.deepFirst(of: "name", "Name", "title", "Title", "original_title").displayString
            ?? fallbackTitle
    }

    private var itemID: String? {
        item.deepFirst(of: "id", "Id", "ItemId", "item_id").displayString
    }

    private var type: String? {
        item.deepFirst(of: "type", "Type", "media_type").displayString
    }

    private var year: String? {
        if let value = item.deepFirst(of: "year", "ProductionYear", "production_year", "premiere_year")
            .displayString, !value.isEmpty {
            return value
        }
        guard let date = item.deepFirst(of: "PremiereDate", "premiere_date", "release_date")
            .displayString, date.count >= 4 else { return nil }
        return String(date.prefix(4))
    }

    private var library: String? {
        item.deepFirst(of: "library_name", "LibraryName", "collection_name", "CollectionName")
            .displayString
    }

    private var path: String? {
        if let value = item.deepFirst(of: "path", "Path").displayString, !value.isEmpty {
            return value
        }
        guard let source = item.deepFirst(of: "MediaSources", "media_sources").array?.first else {
            return nil
        }
        return source.first(of: "Path", "path").displayString
    }

    private var overview: String? {
        item.deepFirst(of: "overview", "Overview", "summary", "description").displayString
    }

    private var directArtworkURL: URL? {
        embyArtworkURL(item, api: session.api, session: session)
    }

    private var artwork: [URL] {
        var seen = Set<String>()
        var urls = images.compactMap { embyArtworkURL($0, api: session.api, session: session) }
        if let directArtworkURL { urls.insert(directArtworkURL, at: 0) }
        return urls
            .filter { seen.insert($0.absoluteString).inserted }
    }

    var body: some View {
        Form {
            if !artwork.isEmpty {
                Section("图片") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(artwork, id: \.absoluteString) { url in
                                RemoteImage(url: url, contentMode: .fit, placeholderIcon: "film")
                                    .frame(width: 180, height: 270)
                                    .background(Color(uiColor: .tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else if !runner.isRunning {
                Section("图片") {
                    EmptyRow(itemID == nil ? "该搜索结果未提供图片或条目 ID" : "该条目暂无可用图片")
                }
            }

            Section("媒体") {
                KeyValueRow("名称", title)
                if let type, !type.isEmpty { KeyValueRow("类型", type) }
                if let year, !year.isEmpty { KeyValueRow("年份", year) }
                if let itemID { KeyValueRow("Emby ID", itemID, monospaced: true) }
                if let rating = item.deepFirst(of: "rating", "CommunityRating", "vote_average").double {
                    KeyValueRow("评分", String(format: "%.1f", rating))
                }
            }

            if let overview, !overview.isEmpty {
                Section("简介") {
                    Text(overview).font(.footnote)
                }
            }

            if library != nil || path != nil {
                Section("位置") {
                    if let library { KeyValueRow("媒体库", library) }
                    if let path { KeyValueRow("路径", path, monospaced: true) }
                }
            }
        }
        .navigationTitle(title)
        .actionFeedback(runner)
        .task(id: itemID) { loadImagesIfNeeded() }
    }

    private func loadImagesIfNeeded() {
        guard directArtworkURL == nil,
              let itemID, !itemID.isEmpty else { return }
        runner.run(nil, operation: {
            let api = try session.requireAPI()
            let connection = try await EmbyConnection.require(api: api)
            return try await api.server.embyGetImages(
                EmbyItemImagesRequest(url: connection.url,
                                      key: connection.key,
                                      publicHost: connection.publicHost,
                                      itemId: itemID,
                                      typeValue: "Primary"))
        }, onSuccess: {
            images = runner.lastResult.list("images", "items", "data")
        })
    }
}

@MainActor
private func embyArtworkURL(_ value: JSONValue, api: CineChillAPI?, session: AppSession) -> URL? {
    let raw = value.displayString
        ?? value.deepFirst(of: "image", "image_url", "imageUrl", "url", "Url", "src",
                           "poster", "poster_url", "cover", "cover_url").displayString
    if let raw, !raw.isEmpty {
        if raw.hasPrefix("/") { return session.absoluteURL(raw) }
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") { return URL(string: raw) }
    }
    return Artwork.url(for: value, api: api, session: session)
}
