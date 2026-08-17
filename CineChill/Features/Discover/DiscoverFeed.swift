import SwiftUI

/// 发现页的数据源。分页参数按各接口的约定分别传 page 或 start。
enum DiscoverFeed: String, CaseIterable, Identifiable {
    case todayPicks, tmdbTrending, tmdbPopularMovies, tmdbPopularTv, tmdbNowPlaying
    case doubanHotMovies, doubanHotTv, doubanHotAnime, doubanNewMovies, doubanNewTv
    case doubanChineseWeekly, doubanGlobalWeekly, doubanTop250, doubanShowing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todayPicks: return "今日精选"
        case .tmdbTrending: return "TMDB 趋势"
        case .tmdbPopularMovies: return "TMDB 热门电影"
        case .tmdbPopularTv: return "TMDB 热门剧集"
        case .tmdbNowPlaying: return "正在上映"
        case .doubanHotMovies: return "豆瓣热门电影"
        case .doubanHotTv: return "豆瓣热门剧集"
        case .doubanHotAnime: return "豆瓣热门动画"
        case .doubanNewMovies: return "豆瓣新片"
        case .doubanNewTv: return "豆瓣新剧"
        case .doubanChineseWeekly: return "华语口碑周榜"
        case .doubanGlobalWeekly: return "全球口碑周榜"
        case .doubanTop250: return "豆瓣 Top250"
        case .doubanShowing: return "豆瓣上映中"
        }
    }

    /// 是否使用 start/count 分页（豆瓣系接口）。
    var usesOffset: Bool {
        switch self {
        case .todayPicks, .tmdbTrending, .tmdbPopularMovies, .tmdbPopularTv, .tmdbNowPlaying:
            return false
        default:
            return true
        }
    }

    /// 部分豆瓣列表不返回媒体类型，需要按接口语义补齐，避免剧集被回退显示成电影。
    var mediaTypeHint: String? {
        switch self {
        case .tmdbPopularTv, .doubanHotTv, .doubanNewTv,
             .doubanChineseWeekly, .doubanGlobalWeekly:
            return "tv"
        case .tmdbPopularMovies, .tmdbNowPlaying, .doubanHotMovies,
             .doubanNewMovies, .doubanTop250, .doubanShowing:
            return "movie"
        case .todayPicks, .tmdbTrending, .doubanHotAnime:
            return nil
        }
    }

    func load(api: CineChillAPI, page: Int) async throws -> JSONValue {
        let start = (page - 1) * 20
        switch self {
        case .todayPicks: return try await api.discover.todayPicks()
        case .tmdbTrending: return try await api.discover.tmdbTrending(page: page)
        case .tmdbPopularMovies: return try await api.discover.tmdbPopularMovies(page: page)
        case .tmdbPopularTv: return try await api.discover.tmdbPopularTv(page: page)
        case .tmdbNowPlaying: return try await api.discover.tmdbNowPlaying(page: page)
        case .doubanHotMovies: return try await api.discover.doubanHotMovies(start: start, count: 20)
        case .doubanHotTv: return try await api.discover.doubanHotTv(start: start, count: 20)
        case .doubanHotAnime: return try await api.discover.doubanHotAnime(start: start, count: 20)
        case .doubanNewMovies: return try await api.discover.doubanNewMovies(start: start, count: 20)
        case .doubanNewTv: return try await api.discover.doubanNewTv(start: start, count: 20)
        case .doubanChineseWeekly: return try await api.discover.doubanChineseWeekly(start: start, count: 20)
        case .doubanGlobalWeekly: return try await api.discover.doubanGlobalWeekly(start: start, count: 20)
        case .doubanTop250: return try await api.discover.doubanTop250(start: start, count: 20)
        case .doubanShowing: return try await api.discover.doubanShowing(start: start, count: 20)
        }
    }
}
