import SwiftUI

/// Emby 搜索：直接检索媒体服务器条目并展示媒体详情。
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
            AsyncImage(url: Artwork.url(for: item, api: session.api, session: session)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.secondary.opacity(0.15)
                }
            }
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

    private var title: String {
        item.first(of: "name", "Name", "title", "Title", "original_title").displayString
            ?? fallbackTitle
    }

    var body: some View {
        Form {
            Section("媒体") {
                KeyValueRow("名称", title)
                KeyValueRow("类型", item.first(of: "type", "Type", "media_type"))
                KeyValueRow("年份", item.first(of: "year", "ProductionYear", "premiere_year"))
                KeyValueRow("Emby ID", item.first(of: "id", "Id", "ItemId"), monospaced: true)
                if let rating = item.first(of: "rating", "CommunityRating", "vote_average").double {
                    KeyValueRow("评分", String(format: "%.1f", rating))
                }
            }

            if let overview = item.first(of: "overview", "Overview", "summary", "description").displayString,
               !overview.isEmpty {
                Section("简介") {
                    Text(overview).font(.footnote)
                }
            }

            Section("位置") {
                KeyValueRow("媒体库", item.first(of: "library", "LibraryName", "collection_name"))
                KeyValueRow("路径", item.first(of: "path", "Path"), monospaced: true)
            }
        }
        .navigationTitle(title)
    }
}
