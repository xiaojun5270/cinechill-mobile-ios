import SwiftUI
import UIKit

private struct LibraryLookupResult {
    let exists: Bool
    let itemID: String?
    let serverIndex: Int
}

/// 影视详情：TMDB 详情 + 本地库状态 + 订阅 / 入库检查。
struct MediaDetailView: View {
    let summary: MediaSummary

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var libraryLookup: LibraryLookupResult?

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
            actionCard(detail)
            seasonsCard(detail)
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

    private func actionCard(_ detail: JSONValue) -> some View {
        CardSection(title: "操作", systemImage: "bolt") {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    subscribe()
                } label: {
                    Label("订阅到 MoviePilot", systemImage: "bell.badge")
                }
                Button {
                    checkLibrary(detail)
                } label: {
                    Label("检查是否已入库", systemImage: "magnifyingglass.circle")
                }
                Button {
                    openInEmby(detail)
                } label: {
                    Label("在 Emby 中打开", systemImage: "play.rectangle.on.rectangle")
                }
                if let libraryLookup {
                    Label {
                        Text(libraryLookup.exists
                             ? libraryLookup.itemID.map { "已入库 · Emby ID \($0)" } ?? "已入库"
                             : "未入库")
                    } icon: {
                        Image(systemName: libraryLookup.exists ? "checkmark.circle.fill" : "xmark.circle")
                    }
                    .font(.caption)
                    .foregroundStyle(libraryLookup.exists ? Color.green : Color.secondary)
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

    private func checkLibrary(_ detail: JSONValue) {
        guard let id = summary.tmdbID else {
            runner.alertIsError = true
            runner.alertText = "该条目没有 TMDB ID，无法检查入库状态"
            return
        }
        runner.run(nil, operation: {
            let api = try session.requireAPI()
            let lookup = try await resolveLibraryTarget(api: api, detail: detail, tmdbID: id)
            let message = lookup.exists
                ? lookup.itemID.map { "媒体库中已存在（Emby ID \($0)）" } ?? "媒体库中已存在"
                : "媒体库中未找到"
            var response: [String: JSONValue] = [
                "success": .bool(true),
                "exists": .bool(lookup.exists),
                "server_idx": .int(lookup.serverIndex),
                "message": .string(message),
            ]
            if let itemID = lookup.itemID { response["emby_item_id"] = .string(itemID) }
            return .object(response)
        }, onSuccess: {
            let result = runner.lastResult
            libraryLookup = LibraryLookupResult(
                exists: result["exists"].bool ?? false,
                itemID: result["emby_item_id"].displayString,
                serverIndex: result["server_idx"].int ?? 0)
            runner.alertIsError = false
            runner.alertText = result["message"].displayString ?? "检查完成"
        })
    }

    private func openInEmby(_ detail: JSONValue) {
        guard let tmdbID = summary.tmdbID else {
            runner.alertIsError = true
            runner.alertText = "该条目没有 TMDB ID，无法定位 Emby 条目"
            return
        }
        let cachedLookup = libraryLookup
        runner.run(nil, operation: {
            let api = try session.requireAPI()
            let lookup: LibraryLookupResult
            if let cachedLookup, cachedLookup.exists, cachedLookup.itemID != nil {
                lookup = cachedLookup
            } else {
                lookup = try await resolveLibraryTarget(api: api, detail: detail, tmdbID: tmdbID)
            }
            guard lookup.exists else {
                return .object(["success": .bool(false), "detail": .string("媒体库中未找到该条目")])
            }
            guard let itemID = lookup.itemID, !itemID.isEmpty else {
                return .object(["success": .bool(false),
                                "detail": .string("已确认入库，但未能解析 Emby ItemId")])
            }
            let result = try await api.discover.getEmbyWebUrl(
                serverIdx: lookup.serverIndex, itemId: itemID)
            if let link = result.displayString
                ?? result.deepFirst(of: "url", "web_url", "webUrl", "link").displayString,
               let url = externalURL(link) {
                await MainActor.run { UIApplication.shared.open(url) }
                return .object(["success": .bool(true),
                                "exists": .bool(true),
                                "emby_item_id": .string(itemID),
                                "server_idx": .int(lookup.serverIndex)])
            }
            return .object(["success": .bool(false), "detail": .string("未获取到 Emby 打开地址")])
        }, onSuccess: {
            libraryLookup = LibraryLookupResult(
                exists: true,
                itemID: runner.lastResult["emby_item_id"].displayString,
                serverIndex: runner.lastResult["server_idx"].int ?? 0)
        })
    }

    private func resolveLibraryTarget(api: CineChillAPI, detail: JSONValue,
                                      tmdbID: Int) async throws -> LibraryLookupResult {
        if let directID = directEmbyItemID(detail) ?? directEmbyItemID(summary.raw) {
            let serverIndex = directServerIndex(detail)
                ?? directServerIndex(summary.raw)
                ?? 0
            return LibraryLookupResult(exists: true, itemID: directID, serverIndex: serverIndex)
        }

        let existenceKey = "\(tmdbID):\(summary.mediaType)"
        let title = mediaTitle(detail)
        let year = mediaYear(detail)
        let item = JSONValue.object([
            "tmdb_id": .int(tmdbID),
            "title": .string(title),
            "year": .string(year),
            "media_type": .string(summary.mediaType),
            "source": .string(summary.raw["source"].displayString ?? ""),
            "id": summary.raw["id"].isNull ? .string("") : summary.raw["id"],
            "_existence_key": .string(existenceKey),
        ])

        var endpointExists = false
        var existenceError: Error?
        do {
            let result = try await api.discover.checkLibraryExists(
                .array([item]), resolveMissing: false)
            endpointExists = result["results"][existenceKey].bool
                ?? result.deepFirst(of: "exists", "in_library", "found").bool
                ?? false
        } catch {
            existenceError = error
        }

        var matchedItem: JSONValue = .null
        do {
            let connection = try await EmbyConnection.require(api: api)
            let searchResult = try await api.server.embySearch(
                EmbySearchRequest(url: connection.url,
                                  key: connection.key,
                                  publicHost: connection.publicHost,
                                  query: title,
                                  libraryId: nil,
                                  typeValue: "Primary"))
            matchedItem = bestEmbyMatch(in: searchResult, title: title,
                                        year: year, tmdbID: tmdbID)
        } catch {
            if let existenceError { throw existenceError }
        }

        let matchedID = matchedItem.first(of: "id", "Id", "ItemId", "item_id").displayString
        if let existenceError, matchedID == nil { throw existenceError }
        return LibraryLookupResult(exists: endpointExists || matchedID != nil,
                                   itemID: matchedID,
                                   serverIndex: matchedItem.first(of: "server_idx", "serverIndex").int ?? 0)
    }

    private func bestEmbyMatch(in response: JSONValue, title: String,
                               year: String, tmdbID: Int) -> JSONValue {
        var items = response.list("items", "results", "data", "Items")
        if items.isEmpty {
            for key in ["data", "result", "payload"] {
                items = response[key].list("items", "results", "Items")
                if !items.isEmpty { break }
            }
        }
        let expectedTitle = normalizedMediaTitle(title)
        let expectedType = summary.mediaType == "tv" ? "series" : "movie"
        guard let match = items.max(by: {
            matchScore($0, expectedTitle: expectedTitle,
                       expectedYear: year, expectedType: expectedType,
                       tmdbID: tmdbID)
                < matchScore($1, expectedTitle: expectedTitle,
                             expectedYear: year, expectedType: expectedType,
                             tmdbID: tmdbID)
        }) else { return .null }
        return matchScore(match, expectedTitle: expectedTitle,
                          expectedYear: year, expectedType: expectedType,
                          tmdbID: tmdbID) > 0 ? match : .null
    }

    private func matchScore(_ item: JSONValue, expectedTitle: String,
                            expectedYear: String, expectedType: String,
                            tmdbID: Int) -> Int {
        let candidateTitle = normalizedMediaTitle(
            item.first(of: "name", "Name", "title", "Title").displayString ?? "")
        let providerIDs = item.deepFirst(of: "ProviderIds", "provider_ids")
        let candidateTMDB = providerIDs.first(of: "Tmdb", "tmdb", "tmdb_id").int
            ?? item.first(of: "tmdb_id", "tmdbId").int
        let candidateType = item.first(of: "type", "Type", "media_type")
            .displayString?.lowercased() ?? ""
        let candidateYear = item.first(of: "year", "ProductionYear", "production_year")
            .displayString ?? ""
        let titleMatches = !candidateTitle.isEmpty
            && (candidateTitle == expectedTitle
                || candidateTitle.contains(expectedTitle)
                || expectedTitle.contains(candidateTitle))
        let typeMatches = candidateType.isEmpty || candidateType.contains(expectedType)
        let yearConflicts = !expectedYear.isEmpty && !candidateYear.isEmpty
            && !candidateYear.hasPrefix(expectedYear)
        guard candidateTMDB == tmdbID || (titleMatches && typeMatches && !yearConflicts) else {
            return 0
        }

        var score = candidateTMDB == tmdbID ? 100 : 50
        if candidateTitle == expectedTitle { score += 30 }
        if candidateType.contains(expectedType) { score += 10 }
        if !expectedYear.isEmpty, candidateYear.hasPrefix(expectedYear) { score += 10 }
        return score
    }

    private func directEmbyItemID(_ value: JSONValue) -> String? {
        for node in [value, value["item"], value["library_item"], value["emby"]] {
            if let itemID = node.first(of: "emby_item_id", "embyItemId", "emby_id",
                                       "EmbyId", "ItemId").displayString,
               !itemID.isEmpty {
                return itemID
            }
        }
        return nil
    }

    private func directServerIndex(_ value: JSONValue) -> Int? {
        for node in [value, value["item"], value["library_item"], value["emby"]] {
            if let index = node.first(of: "server_idx", "serverIndex").int { return index }
        }
        return nil
    }

    private func mediaTitle(_ detail: JSONValue) -> String {
        detail.first(of: "title", "name", "original_title", "original_name").displayString
            ?? summary.title
    }

    private func mediaYear(_ detail: JSONValue) -> String {
        let value = detail.first(of: "year", "ProductionYear", "release_date", "first_air_date")
            .displayString
            ?? summary.raw.first(of: "year", "ProductionYear", "release_date", "first_air_date")
                .displayString
            ?? ""
        return String(value.prefix(4))
    }

    private func normalizedMediaTitle(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private func externalURL(_ value: String) -> URL? {
        if value.hasPrefix("/") { return session.absoluteURL(value) }
        return URL(string: value)
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
