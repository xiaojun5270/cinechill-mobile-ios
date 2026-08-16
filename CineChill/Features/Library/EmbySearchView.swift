import SwiftUI

/// Emby 搜索：直接检索媒体服务器条目，结果可查看图片与原始字段。
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
                        JSONRawScreen(value: item, title: title(item) ?? "条目 \(index + 1)")
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
