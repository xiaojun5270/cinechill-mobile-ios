import SwiftUI

/// 内置榜单直连：直接调用服务端的 RSS 生成接口并预览条目。
enum BuiltinRSSFeed: String, CaseIterable, Identifiable {
    case doubanComing
    case doubanRecommendedMovie
    case doubanRecommendedTv
    case doubanClassification
    case doubanList
    case tmdbTrending
    case tmdbDiscoverMovie
    case iqiyiRank
    case maoyanMovie
    case maoyanPlatform
    case domesticPlatform

    var id: String { rawValue }

    var title: String {
        switch self {
        case .doubanComing: return "豆瓣即将上映"
        case .doubanRecommendedMovie: return "豆瓣推荐电影"
        case .doubanRecommendedTv: return "豆瓣推荐剧集"
        case .doubanClassification: return "豆瓣分类筛选"
        case .doubanList: return "豆瓣片单"
        case .tmdbTrending: return "TMDB 趋势"
        case .tmdbDiscoverMovie: return "TMDB 发现"
        case .iqiyiRank: return "爱奇艺榜单"
        case .maoyanMovie: return "猫眼电影榜"
        case .maoyanPlatform: return "猫眼平台榜"
        case .domesticPlatform: return "国内平台榜"
        }
    }

    var note: String {
        switch self {
        case .doubanList: return "需要填写豆瓣片单 ID（collection_id）"
        case .domesticPlatform: return "平台代码如 tencent / iqiyi / youku / mgtv / bilibili"
        default: return "使用服务端默认参数"
        }
    }

    /// 需要额外输入的自由参数（键 → 提示）。
    var parameterKey: String? {
        switch self {
        case .doubanList: return "片单 ID"
        case .domesticPlatform: return "平台代码"
        case .iqiyiRank: return "分类（可留空）"
        case .maoyanPlatform: return "平台（可留空）"
        default: return nil
        }
    }

    func load(api: CineChillAPI, parameter: String) async throws -> JSONValue {
        let value = parameter.trimmingCharacters(in: .whitespaces)
        switch self {
        case .doubanComing:
            return try await api.rss.doubanComingRss()
        case .doubanRecommendedMovie:
            return try await api.rss.doubanRecommendedRss(subjectType: "movie", score: nil, playable: nil)
        case .doubanRecommendedTv:
            return try await api.rss.doubanRecommendedRss(subjectType: "tv", score: nil, playable: nil)
        case .doubanClassification:
            return try await api.rss.doubanClassificationRss(sort: "recommend", score: nil,
                                                             tags: value.isEmpty ? nil : value,
                                                             pageLimit: 1)
        case .doubanList:
            return try await api.rss.doubanListRss(collectionId: value.isEmpty ? nil : value,
                                                   mediaType: nil, score: nil, playable: nil, pageLimit: 1)
        case .tmdbTrending:
            return try await api.rss.tmdbTrendingRss(mediaType: "all", timeWindow: "week",
                                                     language: "zh-CN", pageLimit: 1, maxItems: 20)
        case .tmdbDiscoverMovie:
            return try await api.rss.tmdbDiscoverRss(mediaType: "movie", watchProvider: nil,
                                                     watchRegion: "CN", sortBy: "popularity.desc",
                                                     language: "zh-CN", pageLimit: 1, maxItems: 20)
        case .iqiyiRank:
            return try await api.rss.iqiyiRankRss(category: value.isEmpty ? nil : value,
                                                  rank: nil, pageLimit: 1)
        case .maoyanMovie:
            return try await api.rss.maoyanMovieRss(kind: nil)
        case .maoyanPlatform:
            return try await api.rss.maoyanPlatformRss(platform: value.isEmpty ? nil : value,
                                                       rank: nil, pageLimit: 1)
        case .domesticPlatform:
            return try await api.rss.domesticPlatformRss(platform: value.isEmpty ? "tencent" : value,
                                                         mtype: nil, pageLimit: 1)
        }
    }
}

struct RSSBuiltinFeedsView: View {
    var body: some View {
        List {
            ForEach(BuiltinRSSFeed.allCases) { feed in
                NavigationLink {
                    BuiltinRSSFeedDetailView(feed: feed)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feed.title)
                        Text(feed.note).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            }
        }
        .navigationTitle("内置榜单直连")
    }
}

struct BuiltinRSSFeedDetailView: View {
    let feed: BuiltinRSSFeed

    @EnvironmentObject private var session: AppSession
    @State private var parameter = ""
    @State private var queryKey = 0

    var body: some View {
        RemoteList(title: feed.title, subtitle: feed.note,
                   cacheKey: "rss-feed-\(feed.id)-\(queryKey)") {
            let api = try session.requireAPI()
            return try await feed.load(api: api, parameter: parameter)
        } content: { value, _ in
            if let key = feed.parameterKey {
                Section("参数") {
                    TextField(key, text: $parameter)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit { queryKey += 1 }
                    Button("重新获取") { queryKey += 1 }
                }
            }
            let items = value.list("items", "entries", "results")
            if items.isEmpty {
                Section { JSONFieldList(value: value) }
            } else {
                Section("条目（\(items.count)）") {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.first(of: "title", "name").displayString ?? "—")
                                .font(.subheadline)
                            HStack(spacing: 8) {
                                if let year = item.first(of: "year", "release_date").displayString {
                                    Text(year)
                                }
                                if let score = item.first(of: "score", "rating", "vote_average").displayString {
                                    Text("★ " + score)
                                }
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .id(queryKey)
    }
}
