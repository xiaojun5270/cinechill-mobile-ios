import SwiftUI

/// 一条龙菜单：整理策略、识别测试、手动整理与维护动作。
struct MediaOrganizeView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    var body: some View {
        List {
            Section("配置") {
                NavigationLink {
                    OrganizeConfigView()
                } label: {
                    Label("整理配置", systemImage: "slider.horizontal.3")
                }
                NavigationLink {
                    RemoteList(title: "默认配置", subtitle: "服务端内置的整理默认值，仅供参考") {
                        let api = try session.requireAPI()
                        return try await api.organize.getDefaultConfig()
                    } content: { value, _ in
                        Section { JSONFieldList(value: value) }
                    }
                } label: {
                    Label("查看默认配置", systemImage: "doc.text.magnifyingglass")
                }
                NavigationLink {
                    SubClassifyConfigView()
                } label: {
                    Label("二级分类设置", systemImage: "square.stack.3d.up")
                }
            }

            Section("工具") {
                NavigationLink {
                    IdentifyTestView()
                } label: {
                    Label("识别测试", systemImage: "text.viewfinder")
                }
                NavigationLink {
                    ManualOrganizeView()
                } label: {
                    Label("手动整理", systemImage: "play.circle")
                }
                NavigationLink {
                    RemoteList(title: "元数据修复剧集库") {
                        let api = try session.requireAPI()
                        return try await api.organize.getMetadataRepairTvLibraries()
                    } content: { value, _ in
                        let libs = value.list("libraries", "tv_libraries")
                        if libs.isEmpty { EmptyRow() }
                        ForEach(Array(libs.enumerated()), id: \.offset) { _, lib in
                            KeyValueRow(lib.first(of: "name", "Name").displayString ?? "—",
                                        lib.first(of: "id", "Id"))
                        }
                    }
                } label: {
                    Label("元数据修复剧集库", systemImage: "books.vertical")
                }
            }

            Section {
                maintenanceButton("回填电影合集", icon: "rectangle.stack.badge.plus") {
                    let api = try session.requireAPI()
                    return try await api.organize.backfillMovieCollections()
                }
                maintenanceButton("刷新 Emby 库缓存", icon: "arrow.triangle.2.circlepath") {
                    let api = try session.requireAPI()
                    return try await api.organize.refreshEmbyLibCache()
                }
                maintenanceButton("同步 Emby 刮削器", icon: "square.and.arrow.up.on.square") {
                    let api = try session.requireAPI()
                    return try await api.organize.syncEmbyLibraryScrapers(.object([:]))
                }
                maintenanceButton("修正 Emby 语言默认值", icon: "globe.asia.australia") {
                    let api = try session.requireAPI()
                    return try await api.organize.fixEmbyLibraryLocaleDefaults(.object([:]))
                }
            } header: {
                Text("维护")
            } footer: {
                Text("以上动作会直接作用于服务端与 Emby，执行后请在任务中心查看进度。")
            }
        }
        .navigationTitle("一条龙菜单")
        .actionFeedback(runner)
    }

    private func maintenanceButton(_ title: String, icon: String,
                                   operation: @escaping () async throws -> JSONValue) -> some View {
        Button {
            runner.run("已提交：" + title, operation: operation)
        } label: {
            Label(title, systemImage: icon)
        }
    }
}

/// 整理配置：字段极多，交给通用 JSON 编辑器并原样保存，兼容服务端新增字段。
struct OrganizeConfigView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        JSONConfigScreen(
            title: "整理配置",
            note: "字段与 Web 后台一致。命名模板中的 {title}、{year}、{season_episode} 等占位符保持原样即可。",
            load: {
                let api = try session.requireAPI()
                return try await api.organize.getConfig()
            },
            save: { edited in
                let api = try session.requireAPI()
                return try await api.organize.saveConfigPreservingFields(edited)
            })
    }
}

/// 只编辑 Web“重命名模板”对应的五个字段，保存时保留其余整理配置。
struct RenameTemplateView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    @State private var phase: Phase = .loading
    @State private var config: JSONValue = .null
    @State private var defaults: JSONValue = .null
    @State private var movieFolder = ""
    @State private var movieFile = ""
    @State private var tvFolder = ""
    @State private var tvSeasonFolder = ""
    @State private var tvEpisode = ""

    private enum Phase: Equatable {
        case loading
        case ready
        case failed(String)
    }

    private var canSave: Bool {
        [movieFolder, movieFile, tvFolder, tvSeasonFolder, tvEpisode]
            .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        Form {
            switch phase {
            case .loading:
                LoadingRow()
            case .failed(let message):
                FailureRow(message: message) { Task { await load() } }
            case .ready:
                Section("电影重命名") {
                    templateField("电影目录", text: $movieFolder)
                    templateField("电影文件名", text: $movieFile)
                    Button("恢复电影默认模板") { restoreMovieDefaults() }
                }

                Section("剧集重命名") {
                    templateField("剧集目录", text: $tvFolder)
                    templateField("季目录", text: $tvSeasonFolder)
                    templateField("剧集文件名", text: $tvEpisode)
                    Button("恢复剧集默认模板") { restoreTVDefaults() }
                }

                Section {
                    Button {
                        save()
                    } label: {
                        Label("保存重命名模板", systemImage: "square.and.arrow.down")
                    }
                    .disabled(!canSave)
                } footer: {
                    Text("支持 {title}、{year}、{tmdb_id}、{season_episode} 等占位符。保存只更新模板字段，不会覆盖其他整理设置。")
                }
            }
        }
        .navigationTitle("重命名模板")
        .actionFeedback(runner)
        .task {
            if phase == .loading { await load() }
        }
    }

    private func templateField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text, axis: .vertical)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(.body, design: .monospaced))
            .lineLimit(2...4)
    }

    private func load() async {
        phase = .loading
        do {
            let api = try session.requireAPI()
            async let currentRequest = api.organize.getConfig()
            async let defaultsRequest = api.organize.getDefaultConfig()
            let (currentResponse, defaultsResponse) = try await (currentRequest, defaultsRequest)
            config = Self.unwrap(currentResponse)
            defaults = Self.unwrap(defaultsResponse)
            applyCurrentValues()
            phase = .ready
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            phase = .failed(error.errorDescription ?? "加载失败")
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func applyCurrentValues() {
        movieFolder = template("movie_folder_format", in: config,
                               fallback: "{title} ({year}) {tmdb-{tmdb_id}}")
        movieFile = template("movie_rename_format", in: config,
                             fallback: "{title}.{year}.{resource_pix}.{video_encode}")
        tvFolder = template("tv_folder_format", in: config,
                            fallback: "{title} ({year}) {tmdb-{tmdb_id}}")
        tvSeasonFolder = template("tv_season_folder_format", in: config,
                                  fallback: "Season {season_num}")
        tvEpisode = template("tv_episode_format", in: config,
                             fallback: "{title}.{season_episode}.{resource_pix}.{video_encode}")
    }

    private func restoreMovieDefaults() {
        movieFolder = template("movie_folder_format", in: defaults,
                               fallback: "{title} ({year}) {tmdb-{tmdb_id}}")
        movieFile = template("movie_rename_format", in: defaults,
                             fallback: "{title}.{year}.{resource_pix}.{web_source}.{resource_type}.{resource_effect}.{video_encode}.{color_depth}.{video_effect}.{fps}.{audio_encode}-{resource_team}")
    }

    private func restoreTVDefaults() {
        tvFolder = template("tv_folder_format", in: defaults,
                            fallback: "{title} ({year}) {tmdb-{tmdb_id}}")
        tvSeasonFolder = template("tv_season_folder_format", in: defaults,
                                  fallback: "Season {season_num}")
        tvEpisode = template("tv_episode_format", in: defaults,
                             fallback: "{title}.{season_episode}.{year}.{resource_pix}.{web_source}.{resource_type}.{video_encode}.{color_depth}.{video_effect}.{fps}.{audio_encode}-{resource_team}")
    }

    private func save() {
        var updated = config
        updated["movie_folder_format"] = .string(movieFolder)
        updated["movie_rename_format"] = .string(movieFile)
        updated["tv_folder_format"] = .string(tvFolder)
        updated["tv_season_folder_format"] = .string(tvSeasonFolder)
        updated["tv_episode_format"] = .string(tvEpisode)
        runner.run("重命名模板已保存", operation: {
            let api = try session.requireAPI()
            return try await api.organize.saveConfigPreservingFields(updated)
        }, onSuccess: {
            config = updated
        })
    }

    private func template(_ key: String, in value: JSONValue, fallback: String) -> String {
        guard let text = value[key].string, !text.isEmpty else { return fallback }
        return text
    }

    private static func unwrap(_ value: JSONValue) -> JSONValue {
        for key in ["config", "data", "settings"] where value[key].object != nil {
            return value[key]
        }
        return value
    }
}

/// 二级分类设置（含 Emby 同步配置）：单独读取并保存 sub_classify 部分，
/// 不影响「二级分类规则」页面里 movie/tv 规则列表的保存。
struct SubClassifyConfigView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        JSONConfigScreen(
            title: "二级分类设置",
            note: "内容取自二级分类规则接口：若服务端把设置放在 sub_classify 字段里会自动展开，否则展示整份规则配置。保存只提交到二级分类保存接口（含 Emby 同步配置），规则列表本身请在「二级分类规则」页面维护。",
            unwrapKeys: [],
            load: {
                let api = try session.requireAPI()
                let response = try await api.organize.getCategoryRules()
                let node = response.deepFirst(of: "sub_classify", "subClassify", "sub_classify_config")
                if node.object != nil { return node }
                for key in ["data", "config", "rules"] where response[key].object != nil {
                    return response[key]
                }
                return response
            },
            save: { edited in
                let api = try session.requireAPI()
                return try await api.organize.saveSubClassify(edited)
            })
    }
}

/// 识别测试：输入文件名，查看解析结果。
struct IdentifyTestView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var folderName = ""
    @State private var fileName = ""
    @State private var mediaType = "auto"

    private let types = ["auto", "movie", "tv"]

    var body: some View {
        Form {
            Section("输入") {
                TextField("目录名（可留空）", text: $folderName)
                    .textInputAutocapitalization(.never)
                TextField("文件名", text: $fileName)
                    .textInputAutocapitalization(.never)
                Picker("媒体类型", selection: $mediaType) {
                    ForEach(types, id: \.self) { type in
                        Text(type == "auto" ? "自动" : (type == "movie" ? "电影" : "剧集")).tag(type)
                    }
                }
            }
            Section {
                Button("开始识别") {
                    runner.run(nil) {
                        let api = try session.requireAPI()
                        return try await api.organize.identifyTest(
                            IdentifyTestPayload(input: fileName, folderName: folderName,
                                                fileName: fileName, mediaType: mediaType))
                    }
                }
                .disabled(fileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if !runner.lastResult.isEmptyContainer {
                Section("识别结果") {
                    JSONFieldList(value: runner.lastResult)
                }
            }
        }
        .navigationTitle("识别测试")
        .actionFeedback(runner)
    }
}

/// 手动整理：触发一次整理流程。
struct ManualOrganizeView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var mediaType = ""
    @State private var isBluray = false
    @State private var overwrite = false

    var body: some View {
        Form {
            Section("参数") {
                Picker("媒体类型", selection: $mediaType) {
                    Text("全部").tag("")
                    Text("电影").tag("movie")
                    Text("剧集").tag("tv")
                }
                Toggle("蓝光原盘", isOn: $isBluray)
                Toggle("覆盖已存在文件", isOn: $overwrite)
            }
            Section {
                Button {
                    runner.run("已提交整理任务") {
                        let api = try session.requireAPI()
                        return try await api.organize.organizeMedia(
                            OrganizeRequest(mediaType: mediaType, isBluray: isBluray, overwrite: overwrite))
                    }
                } label: {
                    Label("开始整理", systemImage: "play.fill")
                }
            } footer: {
                Text("整理会移动/硬链接网盘文件，请确认配置正确后再执行。进度可在「自动化 → 任务中心」查看。")
            }
        }
        .navigationTitle("手动整理")
        .actionFeedback(runner)
    }
}
