import SwiftUI

/// Emby 总览：媒体库列表、封面、随机背景池、连接测试。
struct EmbyOverviewView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    var body: some View {
        RemoteScroll(title: "Emby 总览") {
            let api = try session.requireAPI()
            guard let connection = await EmbyConnection.load(api: api) else {
                return JSONValue.object(["_missing": .bool(true)])
            }
            let overview = await Probe.json { try await api.server.getDashboardEmbyOverview(connection) }
            let covers = await Probe.json { try await api.server.getLibraryCovers(connection) }
            return JSONValue.object(["overview": overview, "covers": covers])
        } content: { value, _ in
            if value["_missing"].bool == true {
                CardSection(title: "尚未配置 Emby", systemImage: "exclamationmark.triangle") {
                    Text("未能从服务端配置中读取到 Emby 地址与 API Key，请先在「设置 → 服务器配置」中填写。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                overviewCard(value["overview"])
                librariesCard(value["overview"], covers: value["covers"])
                toolsCard(libraries: libraryList(value["overview"], covers: value["covers"]))
            }
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func overviewCard(_ overview: JSONValue) -> some View {
        let status = overview.deepFirst(of: "status", "state", "online")
        CardSection(title: overview.deepFirst(of: "server_name", "ServerName", "name").displayString ?? "Emby Server",
                    systemImage: "server.rack",
                    trailing: AnyView(StatusBadge(statusText(status), tone: badgeTone(for: statusText(status))))) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricTile(title: "电影",
                           value: Fmt.text(overview.deepFirst(of: "movie_count", "movies", "MovieCount")),
                           systemImage: "film")
                MetricTile(title: "电视剧",
                           value: Fmt.text(overview.deepFirst(of: "series_count", "series", "SeriesCount")),
                           systemImage: "tv", tone: .good)
                MetricTile(title: "剧集",
                           value: Fmt.text(overview.deepFirst(of: "episode_count", "episodes", "EpisodeCount")),
                           systemImage: "list.and.film", tone: .warning)
                MetricTile(title: "用户",
                           value: Fmt.text(overview.deepFirst(of: "user_count", "users", "UserCount")),
                           systemImage: "person.2", tone: .neutral)
            }
            if let version = overview.deepFirst(of: "version", "Version").displayString {
                KeyValueRow("服务端版本", version)
            }
        }
    }

    private func statusText(_ value: JSONValue) -> String {
        if let bool = value.bool { return bool ? "在线" : "离线" }
        return value.displayString ?? "未知"
    }

    /// 媒体库列表：总览接口没给就退回封面接口的条目。
    private func libraryList(_ overview: JSONValue, covers: JSONValue) -> [JSONValue] {
        overview.deepFirst(of: "libraries", "views", "library_list").array ?? mediaItemList(covers)
    }

    @ViewBuilder
    private func librariesCard(_ overview: JSONValue, covers: JSONValue) -> some View {
        let libraries = libraryList(overview, covers: covers)
        if !libraries.isEmpty {
            CardSection(title: "媒体库", systemImage: "rectangle.stack") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(libraries.enumerated()), id: \.offset) { _, library in
                            PosterCard(
                                title: library.first(of: "name", "Name", "title").displayString ?? "—",
                                subtitle: library.first(of: "count", "item_count", "ItemCount").displayString
                                    .map { $0 + " 部" },
                                url: Artwork.url(for: library, api: session.api, session: session),
                                width: 128)
                        }
                    }
                }
            }
        }
    }
    /// 工具区：连接测试 + 图片/随机池调试入口。
    @ViewBuilder
    private func toolsCard(libraries: [JSONValue]) -> some View {
        CardSection(title: "工具", systemImage: "wrench.and.screwdriver") {
            Button {
                runner.run("连接正常", operation: {
                    let api = try session.requireAPI()
                    return try await api.server.connect(try await EmbyConnection.require(api: api))
                })
            } label: {
                Label("测试 Emby 连接", systemImage: "bolt.horizontal.circle")
            }
            .buttonStyle(.borderless)
            .disabled(runner.isRunning)

            NavigationLink {
                EmbyArtworkToolsView(libraries: libraries)
            } label: {
                Label("图片与随机池", systemImage: "photo.on.rectangle.angled").font(.subheadline)
            }

            NavigationLink {
                EmbySearchView()
            } label: {
                Label("搜索媒体库条目", systemImage: "text.magnifyingglass").font(.subheadline)
            }

            NavigationLink {
                EmbyItemsDeleteView()
            } label: {
                Label("删除 Emby 剧集条目", systemImage: "trash")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }

            if let text = runner.lastResult.displayString, !text.isEmpty {
                Text(text).font(.caption).foregroundStyle(.secondary).lineLimit(3)
            }
        }
    }
}

/// Emby 图片工具：按媒体库拉随机图片池，或按条目 ID 查看全部图片。
struct EmbyArtworkToolsView: View {
    let libraries: [JSONValue]
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    @State private var libraryID = ""
    @State private var imageType = "Backdrop"
    @State private var limit = 20
    @State private var itemID = ""
    @State private var pool: [JSONValue] = []
    @State private var itemImages: [JSONValue] = []

    private let types = ["Backdrop", "Primary", "Thumb", "Logo", "Banner"]

    var body: some View {
        Form {
            librarySection
            poolSection
            itemSection
        }
        .navigationTitle("图片与随机池")
        .actionFeedback(runner)
    }

    @ViewBuilder
    private var librarySection: some View {
        Section("随机图片池") {
            if libraries.isEmpty {
                TextField("媒体库 ID", text: $libraryID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                Picker("媒体库", selection: $libraryID) {
                    Text("请选择").tag("")
                    ForEach(Array(libraries.enumerated()), id: \.offset) { _, library in
                        Text(library.first(of: "name", "Name", "title").displayString ?? "—")
                            .tag(libraryIdentifier(library))
                    }
                }
            }
            Picker("图片类型", selection: $imageType) {
                ForEach(types, id: \.self) { Text($0).tag($0) }
            }
            Stepper("数量 \(limit)", value: $limit, in: 1...100, step: 5)
            Button("拉取随机池") { loadPool() }
                .disabled(runner.isRunning || libraryID.isEmpty)
        }
    }

    @ViewBuilder
    private var poolSection: some View {
        if !pool.isEmpty {
            Section("随机池结果（\(pool.count)）") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(pool.enumerated()), id: \.offset) { index, item in
                            PosterCard(title: item.first(of: "name", "Name", "title").displayString ?? "#\(index + 1)",
                                       subtitle: item.first(of: "type", "Type", "image_type").displayString,
                                       url: imageURL(item),
                                       width: 150)
                        }
                    }
                    .padding(.vertical, 4)
                }
                JSONInspector(value: .array(pool), title: "随机池原始数据")
            }
        }
    }

    @ViewBuilder
    private var itemSection: some View {
        Section("条目图片") {
            TextField("条目 ID（Emby ItemId）", text: $itemID)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("查询条目图片") { loadItemImages() }
                .disabled(runner.isRunning || itemID.trimmingCharacters(in: .whitespaces).isEmpty)
            ForEach(Array(itemImages.enumerated()), id: \.offset) { index, image in
                HStack(spacing: 12) {
                    AsyncImage(url: imageURL(image)) { phase in
                        if let img = phase.image {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Color.secondary.opacity(0.15)
                        }
                    }
                    .frame(width: 72, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(image.first(of: "type", "Type", "ImageType").displayString ?? "图片 \(index + 1)")
                            .font(.subheadline)
                        if let size = image.first(of: "width", "Width").displayString,
                           let height = image.first(of: "height", "Height").displayString {
                            Text("\(size) × \(height)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            if !itemImages.isEmpty {
                JSONInspector(value: .array(itemImages), title: "条目图片原始数据")
            }
        }
    }

    private func libraryIdentifier(_ library: JSONValue) -> String {
        library.first(of: "id", "Id", "library_id", "ItemId", "guid").displayString ?? ""
    }

    /// 接口可能返回完整 URL、相对路径，或者只给条目信息，交给通用规则兜底。
    private func imageURL(_ item: JSONValue) -> URL? {
        if let text = item.first(of: "url", "Url", "image_url", "image", "src").displayString, !text.isEmpty {
            if text.hasPrefix("/") { return session.absoluteURL(text) }
            if text.hasPrefix("http") { return URL(string: text) }
        }
        return Artwork.url(for: item, api: session.api, session: session)
    }

    private func loadPool() {
        runner.run(nil, operation: {
            let api = try session.requireAPI()
            let connection = try await EmbyConnection.require(api: api)
            return try await api.server.embyRandomPool(
                EmbyRandomPoolRequest(url: connection.url,
                                      key: connection.key,
                                      publicHost: connection.publicHost,
                                      libraryId: libraryID,
                                      typeValue: imageType,
                                      limit: limit))
        }, onSuccess: {
            pool = runner.lastResult.list("items", "images", "data", "pool")
        })
    }

    private func loadItemImages() {
        runner.run(nil, operation: {
            let api = try session.requireAPI()
            let connection = try await EmbyConnection.require(api: api)
            return try await api.server.embyGetImages(
                EmbyItemImagesRequest(url: connection.url,
                                      key: connection.key,
                                      publicHost: connection.publicHost,
                                      itemId: itemID.trimmingCharacters(in: .whitespaces),
                                      typeValue: imageType))
        }, onSuccess: {
            itemImages = runner.lastResult.list("items", "images", "data")
        })
    }
}
