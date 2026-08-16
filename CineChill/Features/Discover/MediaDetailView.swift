import SwiftUI
import UIKit

/// 影视详情：TMDB 详情 + 本地库状态 + 订阅 / 入库检查。
struct MediaDetailView: View {
    let summary: MediaSummary

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    var body: some View {
        RemoteScroll(title: summary.title) {
            guard let id = summary.tmdbID else { return summary.raw }
            let api = try session.requireAPI()
            let detail = await Probe.json {
                try await api.discover.mediaDetail(tmdbId: id, type: summary.mediaType)
            }
            let status = summary.mediaType == "tv"
                ? await Probe.json { try await api.discover.librarySeriesStatus(tmdbId: id) }
                : JSONValue.null
            return JSONValue.object(["detail": detail, "status": status])
        } content: { value, _ in
            let detail = value["detail"].isNull ? value : value["detail"]
            backdrop()
            header(detail)
            overview(detail)
            infoCard(detail, status: value["status"])
            actionCard
            seasonsCard(detail)
            CardSection(title: "原始数据", systemImage: "curlybraces") {
                NavigationLink {
                    JSONRawScreen(value: value, title: summary.title)
                } label: {
                    Label("查看接口返回", systemImage: "chevron.right.circle")
                        .font(.subheadline)
                }
            }
        }
        .actionFeedback(runner)
    }

    // MARK: - 头部

    /// 剧照横幅：`/api/discover/tmdb_backdrop/{type}/{id}` 由服务端代理，取不到时整块不显示。
    @ViewBuilder
    private func backdrop() -> some View {
        if let id = summary.tmdbID,
           let url = try? session.api?.discover.tmdbBackdropImageURL(mediaType: summary.mediaType, tmdbId: id) {
            RemoteImage(url: url, placeholderIcon: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
                .frame(height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func header(_ detail: JSONValue) -> some View {
        let poster = summary.tmdbID.flatMap { id in
            try? session.api?.discover.tmdbPosterImageURL(mediaType: summary.mediaType, tmdbId: id)
        } ?? Artwork.url(for: detail, api: session.api, session: session)

        HStack(alignment: .top, spacing: 14) {
            RemoteImage(url: poster, placeholderIcon: "film")
                .frame(width: 108, height: 162)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 8) {
                Text(detail.first(of: "title", "name").displayString ?? summary.title)
                    .font(.headline)
                if let original = detail.first(of: "original_title", "original_name").displayString,
                   original != summary.title {
                    Text(original).font(.caption).foregroundStyle(.secondary)
                }
                if let subtitle = summary.subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    if let badge = summary.badge { StatusBadge("★ " + badge, tone: .warning) }
                    if let id = summary.tmdbID { StatusBadge("TMDB \(id)", tone: .info) }
                }
                if let genres = genreText(detail) {
                    Text(genres).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func genreText(_ detail: JSONValue) -> String? {
        let names = (detail["genres"].array ?? []).compactMap { $0.first(of: "name", "title").string }
        if !names.isEmpty { return names.joined(separator: " / ") }
        return detail.first(of: "genre", "genres_text").displayString
    }

    @ViewBuilder
    private func overview(_ detail: JSONValue) -> some View {
        if let text = detail.first(of: "overview", "summary", "intro", "description").string,
           !text.isEmpty {
            CardSection(title: "简介", systemImage: "text.alignleft") {
                Text(text).font(.footnote)
            }
        }
    }

    // MARK: - 信息

    @ViewBuilder
    private func infoCard(_ detail: JSONValue, status: JSONValue) -> some View {
        CardSection(title: "信息", systemImage: "info.circle") {
            VStack(spacing: 8) {
                KeyValueRow("类型", summary.mediaType == "tv" ? "剧集" : "电影")
                if let date = detail.first(of: "release_date", "first_air_date").displayString {
                    KeyValueRow("上映日期", date)
                }
                if let seasons = detail.first(of: "number_of_seasons").int {
                    KeyValueRow("季数", String(seasons))
                }
                if let episodes = detail.first(of: "number_of_episodes").int {
                    KeyValueRow("总集数", String(episodes))
                }
                if let vote = detail.first(of: "vote_average").double, vote > 0 {
                    KeyValueRow("评分", String(format: "%.1f", vote))
                }
                if !status.isNull, !status.isEmptyContainer {
                    KeyValueRow("本地库", status.first(of: "status", "state", "message").displayString ?? "已收录")
                    if let missing = status.deepFirst(of: "missing_count", "missing").int {
                        KeyValueRow("缺集", "\(missing) 集")
                    }
                }
            }
        }
    }

    // MARK: - 操作

    private var actionCard: some View {
        CardSection(title: "操作", systemImage: "bolt") {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    subscribe()
                } label: {
                    Label("订阅到 MoviePilot", systemImage: "bell.badge")
                }
                Button {
                    checkLibrary()
                } label: {
                    Label("检查是否已入库", systemImage: "magnifyingglass.circle")
                }
                Button {
                    openInEmby()
                } label: {
                    Label("在 Emby 中打开", systemImage: "play.rectangle.on.rectangle")
                }
            }
            .font(.subheadline)
        }
    }

    private func subscribe() {
        guard let id = summary.tmdbID else { return }
        runner.run("已提交订阅") {
            let api = try session.requireAPI()
            return try await api.moviePilot.mpSubscribe(
                SubscribeRequest(tmdbid: id, typeName: summary.mediaType, name: summary.title))
        }
    }

    private func checkLibrary() {
        guard let id = summary.tmdbID else { return }
        runner.run(nil) {
            let api = try session.requireAPI()
            let existenceKey = "\(id):\(summary.mediaType)"
            let year = summary.raw.first(of: "year", "ProductionYear", "release_date", "first_air_date")
                .displayString
                .map { String($0.prefix(4)) } ?? ""
            let item = JSONValue.object([
                "tmdb_id": .int(id),
                "title": .string(summary.title),
                "year": .string(year),
                "media_type": .string(summary.mediaType),
                "source": .string(summary.raw["source"].displayString ?? ""),
                "id": summary.raw["id"].isNull ? .string("") : summary.raw["id"],
                "_existence_key": .string(existenceKey),
            ])
            let result = try await api.discover.checkLibraryExists(.array([item]), resolveMissing: false)
            let exists = result["results"][existenceKey].bool
                ?? result.deepFirst(of: "exists", "in_library", "found").bool
                ?? false
            return JSONValue.object([
                "success": .bool(true),
                "message": .string(exists ? "媒体库中已存在" : "媒体库中未找到"),
            ])
        }
    }

    private func openInEmby() {
        guard let idText = summary.raw.first(of: "emby_item_id", "item_id", "ItemId", "Id").displayString
        else {
            runner.run(nil) {
                JSONValue.object(["success": .bool(false), "detail": .string("该条目没有 Emby ItemId")])
            }
            return
        }
        runner.run(nil) {
            let api = try session.requireAPI()
            let result = try await api.discover.getEmbyWebUrl(serverIdx: nil, itemId: idText)
            if let link = result.deepFirst(of: "url", "web_url", "link").string,
               let url = URL(string: link) {
                await MainActor.run { UIApplication.shared.open(url) }
                return JSONValue.object(["success": .bool(true)])
            }
            return JSONValue.object(["success": .bool(false), "detail": .string("未获取到播放地址")])
        }
    }

    // MARK: - 分季

    @ViewBuilder
    private func seasonsCard(_ detail: JSONValue) -> some View {
        let seasons = detail["seasons"].array ?? []
        if summary.mediaType == "tv", !seasons.isEmpty, let id = summary.tmdbID {
            CardSection(title: "分季", systemImage: "list.number") {
                VStack(spacing: 6) {
                    ForEach(Array(seasons.enumerated()), id: \.offset) { _, season in
                        let number = season.first(of: "season_number", "season", "index").int ?? 0
                        NavigationLink {
                            SeasonDetailView(tmdbID: id, seasonNumber: number,
                                             title: season.first(of: "name").displayString ?? "第 \(number) 季")
                        } label: {
                            HStack {
                                Text(season.first(of: "name").displayString ?? "第 \(number) 季")
                                Spacer()
                                Text("\(season.first(of: "episode_count").int ?? 0) 集")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .font(.subheadline)
            }
        }
    }
}

/// 单季详情。
struct SeasonDetailView: View {
    let tmdbID: Int
    let seasonNumber: Int
    let title: String

    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: title) {
            let api = try session.requireAPI()
            return try await api.discover.seasonDetail(tmdbId: tmdbID, seasonNum: seasonNumber)
        } content: { value, _ in
            let episodes = value.list("episodes")
            if episodes.isEmpty {
                Section { JSONFieldList(value: value) }
            } else {
                ForEach(Array(episodes.enumerated()), id: \.offset) { _, episode in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("E\(episode.first(of: "episode_number", "episode").int ?? 0)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(episode.first(of: "name", "title").displayString ?? "—")
                                .font(.subheadline)
                        }
                        if let air = episode.first(of: "air_date").displayString {
                            Text(air).font(.caption2).foregroundStyle(.secondary)
                        }
                        if let overview = episode.first(of: "overview").string, !overview.isEmpty {
                            Text(overview).font(.caption2).foregroundStyle(.secondary).lineLimit(3)
                        }
                    }
                }
            }
        }
    }
}
