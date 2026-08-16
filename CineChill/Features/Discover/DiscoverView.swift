import SwiftUI

/// 发现页：横向切换数据源 + 海报网格 + 分页加载。
struct DiscoverView: View {
    @EnvironmentObject private var session: AppSession
    @State private var feed: DiscoverFeed = .todayPicks

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DiscoverFeed.allCases) { item in
                        Button {
                            feed = item
                        } label: {
                            Text(item.title)
                                .font(.footnote.weight(feed == item ? .semibold : .regular))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(feed == item ? Color.accentColor.opacity(0.16) : Color(uiColor: .secondarySystemFill),
                                            in: Capsule())
                                .foregroundStyle(feed == item ? Color.accentColor : Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color(uiColor: .systemGroupedBackground))

            FeedGridView(feed: feed)
        }
        .navigationTitle("发现")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    DiscoverBrowseView()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    MediaSearchView()
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
}

/// 单个数据源的分页网格。
struct FeedGridView: View {
    let feed: DiscoverFeed
    @EnvironmentObject private var session: AppSession

    @State private var items: [JSONValue] = []
    @State private var page = 1
    @State private var isLoading = false
    @State private var canLoadMore = true
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let errorText {
                    FailureRow(message: errorText) { Task { await load(reset: true) } }
                }
                PosterGrid(items: items)
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, 12)
                } else if canLoadMore, !items.isEmpty {
                    Button("加载更多") { Task { await load(reset: false) } }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .refreshable { await load(reset: true) }
        .task(id: feed) { await load(reset: true) }
    }

    private func load(reset: Bool) async {
        guard !isLoading else { return }
        isLoading = true
        errorText = nil
        if reset {
            page = 1
            canLoadMore = true
        }
        do {
            let api = try session.requireAPI()
            let response = try await feed.load(api: api, page: page)
            let fetched = mediaItemList(response)
            if reset {
                items = fetched
            } else {
                items.append(contentsOf: fetched)
            }
            canLoadMore = !fetched.isEmpty && fetched.count >= 10
            page += 1
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            if case .cancelled = error {} else { errorText = error.errorDescription }
        } catch {
            errorText = error.localizedDescription
        }
        isLoading = false
    }
}

/// 影视搜索：/api/search_media。
struct MediaSearchView: View {
    @EnvironmentObject private var session: AppSession
    @State private var query = ""
    @State private var items: [JSONValue] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var didSearch = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                } else if let errorText {
                    FailureRow(message: errorText) { Task { await search() } }
                } else if didSearch {
                    PosterGrid(items: items)
                } else {
                    Text("输入片名后回车搜索 TMDB")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("搜索")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "片名 / 关键词")
        .onSubmit(of: .search) { Task { await search() } }
    }

    private func search() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        isLoading = true
        errorText = nil
        do {
            let api = try session.requireAPI()
            let response = try await api.discover.searchMedia(query: text, type: nil, page: 1)
            items = mediaItemList(response)
            didSearch = true
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            errorText = error.errorDescription
        } catch {
            errorText = error.localizedDescription
        }
        isLoading = false
    }
}
