import SwiftUI

/// 从服务端各类列表响应里取出条目数组，兼容 `results` / `subjects` / `data.results` 等写法。
func mediaItemList(_ value: JSONValue) -> [JSONValue] {
    let direct = value.list("subjects", "results", "items", "movies")
    if !direct.isEmpty { return direct }
    for key in ["data", "result", "payload", "media", "response"] {
        let nested = value[key].list("subjects", "results", "items")
        if !nested.isEmpty { return nested }
    }
    return []
}

/// 海报地址推断：TMDB 用图片代理，豆瓣走豆瓣代理，其余外链走通用缓存代理。
@MainActor
enum Artwork {
    static func url(for item: JSONValue, api: CineChillAPI?, session: AppSession) -> URL? {
        if let api, let path = item.first(of: "poster_path", "posterPath").string, path.hasPrefix("/") {
            return try? api.discover.tmdbImageProxyURL(path: path)
        }
        var raw = item.first(of: "poster", "cover", "image", "pic", "poster_url",
                             "cover_url", "img", "image_url").displayString
        if raw == nil, let pic = item["pic"].object {
            raw = (pic["large"] ?? pic["normal"] ?? pic["medium"])?.string
        }
        if raw == nil, let images = item["images"].object {
            raw = (images["large"] ?? images["small"])?.string
        }
        guard let text = raw, !text.isEmpty else { return nil }
        if text.hasPrefix("/") { return session.absoluteURL(text) }
        guard text.hasPrefix("http") else { return nil }
        if text.contains("doubanio") || text.contains("douban") {
            return try? api?.discover.doubanImageProxyURL(url: text)
        }
        if text.contains("bilivideo") || text.contains("hdslb") {
            return try? api?.discover.biliImageProxyURL(url: text)
        }
        if text.contains("bangumi") || text.contains("bgm.tv") {
            return try? api?.discover.bangumiImageProxyURL(url: text)
        }
        return try? api?.discover.cachedConfiguredImageProxyURL(url: text)
    }
}

/// 从各来源（TMDB / 豆瓣 / Emby / 本地库）的条目里提取通用展示字段。
struct MediaSummary {
    let raw: JSONValue
    let title: String
    let subtitle: String?
    let badge: String?
    let tmdbID: Int?
    let mediaType: String

    init(_ item: JSONValue) {
        raw = item
        title = item.first(of: "title", "name", "Name", "original_title", "original_name")
            .displayString ?? "未命名"
        let year = MediaSummary.year(of: item)
        let typeText = item.first(of: "media_type", "type", "mtype").string
        mediaType = MediaSummary.normalizeType(typeText, item: item)
        let typeLabel = mediaType == "tv" ? "剧集" : "电影"
        subtitle = [year, typeLabel].compactMap { $0 }.joined(separator: " · ")
        if let rating = item.first(of: "vote_average", "rating", "score", "douban_score").double,
           rating > 0 {
            badge = String(format: "%.1f", rating)
        } else {
            badge = nil
        }
        tmdbID = item.first(of: "tmdb_id", "tmdbId", "tmdbid", "id").int
    }

    private static func year(of item: JSONValue) -> String? {
        if let year = item.first(of: "year", "ProductionYear").displayString, !year.isEmpty {
            return year
        }
        let date = item.first(of: "release_date", "first_air_date", "pubdate", "air_date").displayString
        if let date, date.count >= 4 { return String(date.prefix(4)) }
        return nil
    }

    private static func normalizeType(_ raw: String?, item: JSONValue) -> String {
        let lower = raw?.lowercased() ?? ""
        if lower.contains("tv") || lower.contains("series") || lower.contains("剧") { return "tv" }
        if lower.contains("movie") || lower.contains("电影") { return "movie" }
        if !item["first_air_date"].isNull || !item["number_of_seasons"].isNull { return "tv" }
        return "movie"
    }
}

/// 海报网格：发现页与搜索结果共用。
struct PosterGrid: View {
    let items: [JSONValue]
    @EnvironmentObject private var session: AppSession

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    var body: some View {
        if items.isEmpty {
            Text("暂无内容")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    let summary = MediaSummary(item)
                    NavigationLink {
                        MediaDetailView(summary: summary)
                    } label: {
                        PosterCard(title: summary.title,
                                   subtitle: summary.subtitle,
                                   badge: summary.badge,
                                   url: Artwork.url(for: item, api: session.api, session: session),
                                   width: 104)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
