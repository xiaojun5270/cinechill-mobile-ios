import Foundation
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
                    OrganizeDefaultConfigView()
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

/// 整理配置：按 Web 后台的功能分组展示，同时保留服务端返回的未知字段。
struct OrganizeConfigView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    @State private var phase: Phase = .loading
    @State private var config: JSONValue = .null
    @State private var defaults: JSONValue = .null
    @State private var libraryOptions: [OrganizeSelectionOption] = []
    @State private var libraryMessage = ""

    private enum Phase: Equatable {
        case loading
        case ready
        case failed(String)
    }

    private static let episodeConditions = [
        OrganizeSelectionOption(id: "no_overview", label: "无简介"),
        OrganizeSelectionOption(id: "non_chinese_overview", label: "非中文简介"),
        OrganizeSelectionOption(id: "default_episode_title", label: "默认集标题")
    ]

    private static let imageConditions = [
        OrganizeSelectionOption(id: "missing_episode_thumb", label: "无图")
    ]

    private static let knownKeys: Set<String> = [
        "drive_index", "source_cid", "source_name", "target_cid", "target_name",
        "failed_cid", "failed_name", "dedup_cid", "dedup_name", "wash_cid", "wash_name",
        "scrape_enabled", "emby_local_scrape", "scrape_nfo", "scrape_poster",
        "scrape_fanart", "scrape_logo", "scrape_banner", "scrape_thumb",
        "scrape_season_poster", "scrape_episode_thumb", "policy_nfo", "policy_poster",
        "policy_fanart", "policy_logo", "policy_banner", "policy_thumb",
        "policy_season_poster", "policy_episode_thumb",
        "metadata_repair_episode_conditions", "metadata_repair_image_conditions",
        "metadata_repair_lookback_days", "metadata_repair_workers",
        "metadata_repair_tv_libraries", "metadata_repair_auto_enabled",
        "metadata_repair_cron", "validation_year_enabled",
        "validation_chinese_title_enabled", "validation_poster_enabled",
        "validation_tv_episode_enabled", "life_monitor_enabled", "life_monitor_start_mode",
        "auto_sync_strm", "emby_scrapers_enabled", "wash_enabled",
        "wash_by_equivalent_size", "wash_tolerance_ratio", "organize_parse_mode",
        "movie_folder_format", "movie_rename_format", "tv_folder_format",
        "tv_season_folder_format", "tv_episode_format"
    ]

    var body: some View {
        Form {
            switch phase {
            case .loading:
                LoadingRow()
            case .failed(let message):
                FailureRow(message: message) { Task { await load() } }
            case .ready:
                directorySection
                automationSection
                validationSection
                scrapeSection
                overwriteSection
                metadataSection
                washSection
                renameSection
                compatibilitySection
                saveSection
            }
        }
        .navigationTitle("整理配置")
        .actionFeedback(runner)
        .task {
            if phase == .loading { await load() }
        }
    }

    private var directorySection: some View {
        Section {
            Stepper("115 网盘序号：\(intValue("drive_index", fallback: 0))",
                    value: intBinding("drive_index", fallback: 0, range: 0...9))
            directoryFields("整理源目录", nameKey: "source_name", cidKey: "source_cid")
            directoryFields("媒体库目录", nameKey: "target_name", cidKey: "target_cid")
            directoryFields("失败目录", nameKey: "failed_name", cidKey: "failed_cid")
            directoryFields("去重目录", nameKey: "dedup_name", cidKey: "dedup_cid")
            directoryFields("洗版目录", nameKey: "wash_name", cidKey: "wash_cid")
        } header: {
            Text("115 网盘与目录")
        } footer: {
            Text("目录名称便于识别，CID 必须填写对应的 115 目录 ID。")
        }
    }

    private var automationSection: some View {
        Section {
            Toggle("115 事件监听", isOn: boolBinding("life_monitor_enabled", fallback: true))
            Picker("首次监听位置", selection: stringBinding("life_monitor_start_mode", fallback: "last")) {
                Text("从上次事件继续").tag("last")
                Text("仅监听最新事件").tag("latest")
            }
            Toggle("整理完成自动同步 STRM", isOn: boolBinding("auto_sync_strm", fallback: true))
            Toggle("启用 Emby 刮削器", isOn: boolBinding("emby_scrapers_enabled"))
            Picker("媒体信息解析", selection: stringBinding("organize_parse_mode", fallback: "ffprobe")) {
                Text("智能 ffprobe").tag("ffprobe")
                Text("全量 ffprobe").tag("ffprobe_full")
            }
        } header: {
            Text("自动整理")
        } footer: {
            Text("全量 ffprobe 会读取每个媒体文件的完整流信息，准确度更高但整理速度更慢。")
        }
    }

    private var validationSection: some View {
        Section {
            Toggle("拦截无有效年份", isOn: boolBinding("validation_year_enabled", fallback: true))
            Toggle("拦截无中文名", isOn: boolBinding("validation_chinese_title_enabled", fallback: true))
            Toggle("拦截无封面", isOn: boolBinding("validation_poster_enabled", fallback: true))
            Toggle("拦截 TMDb 季集不匹配",
                   isOn: boolBinding("validation_tv_episode_enabled", fallback: true))
        } header: {
            Text("入库拦截")
        } footer: {
            Text("完全缺少剧集集号的条目始终会被拦截；关闭季集校验后，仅允许 TMDb 无法对应的季集继续入库。")
        }
    }

    private var scrapeSection: some View {
        Section {
            Toggle("启用整理刮削", isOn: boolBinding("scrape_enabled", fallback: true))
            Toggle("使用 Emby 本地刮削", isOn: boolBinding("emby_local_scrape", fallback: true))
                .disabled(!boolValue("scrape_enabled", fallback: true))
            scrapeToggle("NFO", key: "scrape_nfo")
            scrapeToggle("海报", key: "scrape_poster")
            scrapeToggle("背景图", key: "scrape_fanart")
            scrapeToggle("Logo", key: "scrape_logo")
            scrapeToggle("横幅", key: "scrape_banner")
            scrapeToggle("缩略图", key: "scrape_thumb")
            scrapeToggle("季海报", key: "scrape_season_poster")
            scrapeToggle("剧集缩略图", key: "scrape_episode_thumb")
        } header: {
            Text("刮削内容")
        } footer: {
            Text("关闭总开关后，以下刮削内容设置会保留，但整理时不会执行。")
        }
    }

    private var overwriteSection: some View {
        Section {
            policyPicker("NFO", key: "policy_nfo")
            policyPicker("海报", key: "policy_poster")
            policyPicker("背景图", key: "policy_fanart")
            policyPicker("Logo", key: "policy_logo")
            policyPicker("横幅", key: "policy_banner")
            policyPicker("缩略图", key: "policy_thumb")
            policyPicker("季海报", key: "policy_season_poster")
            policyPicker("剧集缩略图", key: "policy_episode_thumb")
        } header: {
            Text("文件覆盖策略")
        } footer: {
            Text("“仅补缺”不会替换媒体库已有文件；覆盖模式会使用最新刮削结果替换已有文件。")
        }
        .disabled(!boolValue("scrape_enabled", fallback: true))
    }

    private var metadataSection: some View {
        Section {
            Toggle("自动运行元数据补齐",
                   isOn: boolBinding("metadata_repair_auto_enabled", fallback: true))
            TextField("自动运行 Cron",
                      text: stringBinding("metadata_repair_cron", fallback: "0 2 * * *"))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))

            NavigationLink {
                OrganizeMultiSelectView(
                    title: "剧集媒体库范围",
                    options: selectableLibraries,
                    selection: stringArrayBinding("metadata_repair_tv_libraries"),
                    emptyMeansAll: true)
            } label: {
                selectionRow("剧集媒体库范围", key: "metadata_repair_tv_libraries", emptyLabel: "全部")
            }
            .disabled(libraryOptions.isEmpty && stringArrayValue("metadata_repair_tv_libraries").isEmpty)

            NavigationLink {
                OrganizeMultiSelectView(
                    title: "剧集 NFO 修复条件",
                    options: Self.episodeConditions,
                    selection: stringArrayBinding("metadata_repair_episode_conditions"))
            } label: {
                selectionRow("剧集 NFO 修复条件", key: "metadata_repair_episode_conditions")
            }

            NavigationLink {
                OrganizeMultiSelectView(
                    title: "剧集图片修复条件",
                    options: Self.imageConditions,
                    selection: stringArrayBinding("metadata_repair_image_conditions"))
            } label: {
                selectionRow("剧集图片修复条件", key: "metadata_repair_image_conditions")
            }

            Stepper("刷新回溯：\(lookbackLabel)",
                    value: intBinding("metadata_repair_lookback_days", fallback: 60,
                                      range: 0...3650))
            Stepper("本地补齐并发：\(intValue("metadata_repair_workers", fallback: 8))",
                    value: intBinding("metadata_repair_workers", fallback: 8, range: 1...40))
        } header: {
            Text("TMDb 元数据补齐")
        } footer: {
            Text(metadataFooter)
        }
    }

    private var washSection: some View {
        Section {
            Toggle("启用洗版", isOn: boolBinding("wash_enabled"))
            Toggle("按等效体积洗版", isOn: boolBinding("wash_by_equivalent_size"))
                .disabled(!boolValue("wash_enabled"))
            Stepper("体积容差：\(toleranceText)",
                    value: doubleBinding("wash_tolerance_ratio", range: 0...100),
                    in: 0...100,
                    step: 1)
                .disabled(!boolValue("wash_enabled") || !boolValue("wash_by_equivalent_size"))
        } header: {
            Text("洗版策略")
        } footer: {
            Text("容差范围为 0%–100%，用于判断两个资源的体积是否可视为等效。")
        }
    }

    private var renameSection: some View {
        Section {
            templateField("电影目录", key: "movie_folder_format")
            templateField("电影文件名", key: "movie_rename_format")
            templateField("剧集目录", key: "tv_folder_format")
            templateField("季目录", key: "tv_season_folder_format")
            templateField("剧集文件名", key: "tv_episode_format")
        } header: {
            Text("重命名模板")
        } footer: {
            Text("支持 {title}、{year}、{tmdb_id}、{season_episode} 等占位符，请保持花括号完整。")
        }
    }

    @ViewBuilder
    private var compatibilitySection: some View {
        if compatibilityCount > 0 {
            Section {
                NavigationLink {
                    JSONObjectEditorScreen(title: "服务端兼容参数", value: compatibilityBinding)
                } label: {
                    HStack {
                        Label("服务端兼容参数", systemImage: "gearshape.2")
                        Spacer()
                        Text("\(compatibilityCount) 项")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("这里仅显示当前服务端额外返回的参数；保存时会与上方配置一起原样保留。")
            }
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                save()
            } label: {
                Label("保存整理配置", systemImage: "square.and.arrow.down")
            }
            Button("恢复服务端默认值", role: .destructive) {
                restoreDefaults()
            }
        } footer: {
            Text("恢复默认值只更新本页已识别参数，服务端兼容参数不会被删除；点击保存后才会生效。")
        }
    }

    @ViewBuilder
    private func directoryFields(_ title: String, nameKey: String, cidKey: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            TextField("目录名称", text: stringBinding(nameKey, fallback: "根目录"))
            TextField("目录 CID", text: stringBinding(cidKey, fallback: "0"))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))
        }
        .padding(.vertical, 2)
    }

    private func scrapeToggle(_ title: String, key: String) -> some View {
        Toggle(title, isOn: boolBinding(key, fallback: true))
            .disabled(!boolValue("scrape_enabled", fallback: true))
    }

    private func policyPicker(_ title: String, key: String) -> some View {
        let current = stringValue(key, fallback: "missing_only")
        return Picker(title, selection: stringBinding(key, fallback: "missing_only")) {
            Text("仅补缺").tag("missing_only")
            Text("覆盖现有").tag("overwrite")
            if current != "missing_only" && current != "overwrite" {
                Text("当前值（\(current)）").tag(current)
            }
        }
    }

    private func templateField(_ title: String, key: String) -> some View {
        TextField(title, text: stringBinding(key), axis: .vertical)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(.footnote, design: .monospaced))
            .lineLimit(2...5)
    }

    private func selectionRow(_ title: String, key: String, emptyLabel: String = "未选择") -> some View {
        let count = stringArrayValue(key).count
        return HStack {
            Text(title)
            Spacer()
            Text(count == 0 ? emptyLabel : "\(count) 项")
                .foregroundStyle(.secondary)
        }
    }

    private var lookbackLabel: String {
        let days = intValue("metadata_repair_lookback_days", fallback: 60)
        return days == 0 ? "全部历史剧集" : "最近 \(days) 天"
    }

    private var toleranceText: String {
        let value = doubleValue("wash_tolerance_ratio")
        return value == value.rounded() ? "\(Int(value))%" : String(format: "%.1f%%", value)
    }

    private var metadataFooter: String {
        var lines = ["Cron 使用 5 段表达式，默认 0 2 * * *，即按容器时区每天 02:00 运行。回溯天数为 0 时检查全部历史剧集。"]
        if !libraryMessage.isEmpty { lines.append(libraryMessage) }
        return lines.joined(separator: "\n")
    }

    private var selectableLibraries: [OrganizeSelectionOption] {
        var result = libraryOptions
        for value in stringArrayValue("metadata_repair_tv_libraries")
            where !result.contains(where: { $0.id == value }) {
            result.append(OrganizeSelectionOption(id: value, label: value))
        }
        return result
    }

    private var compatibilityCount: Int {
        guard let object = config.object else { return 0 }
        return object.keys.filter { !Self.knownKeys.contains($0) }.count
    }

    private var compatibilityBinding: Binding<JSONValue> {
        Binding(
            get: {
                guard let object = config.object else { return .object([:]) }
                return .object(object.filter { !Self.knownKeys.contains($0.key) })
            },
            set: { newValue in
                var object = config.object ?? [:]
                for key in object.keys where !Self.knownKeys.contains(key) {
                    object.removeValue(forKey: key)
                }
                for (key, value) in newValue.object ?? [:] {
                    object[key] = value
                }
                config = .object(object)
            })
    }

    private func boolValue(_ key: String, fallback: Bool = false) -> Bool {
        config[key].bool ?? defaults[key].bool ?? fallback
    }

    private func boolBinding(_ key: String, fallback: Bool = false) -> Binding<Bool> {
        Binding(
            get: { boolValue(key, fallback: fallback) },
            set: { config[key] = .bool($0) })
    }

    private func stringValue(_ key: String, fallback: String = "") -> String {
        config[key].displayString ?? defaults[key].displayString ?? fallback
    }

    private func stringBinding(_ key: String, fallback: String = "") -> Binding<String> {
        Binding(
            get: { stringValue(key, fallback: fallback) },
            set: { config[key] = .string($0) })
    }

    private func intValue(_ key: String, fallback: Int) -> Int {
        config[key].int ?? defaults[key].int ?? fallback
    }

    private func intBinding(_ key: String, fallback: Int,
                            range: ClosedRange<Int>) -> Binding<Int> {
        Binding(
            get: { min(max(intValue(key, fallback: fallback), range.lowerBound), range.upperBound) },
            set: { config[key] = .int(min(max($0, range.lowerBound), range.upperBound)) })
    }

    private func doubleValue(_ key: String) -> Double {
        config[key].double ?? defaults[key].double ?? 0
    }

    private func doubleBinding(_ key: String,
                               range: ClosedRange<Double>) -> Binding<Double> {
        Binding(
            get: { min(max(doubleValue(key), range.lowerBound), range.upperBound) },
            set: { config[key] = .double(min(max($0, range.lowerBound), range.upperBound)) })
    }

    private func stringArrayValue(_ key: String) -> [String] {
        let value = config[key].array ?? defaults[key].array ?? []
        return value.compactMap(\.displayString)
    }

    private func stringArrayBinding(_ key: String) -> Binding<[String]> {
        Binding(
            get: { stringArrayValue(key) },
            set: { config[key] = .array($0.map(JSONValue.string)) })
    }

    private func load() async {
        phase = .loading
        do {
            let api = try session.requireAPI()
            let currentResponse = try await api.organize.getConfig()
            let defaultResponse = try? await api.organize.getDefaultConfig()
            let librariesResponse = try? await api.organize.getMetadataRepairTvLibraries()

            let builtIn = JSONValue.object(Self.webDefaults)
            let serverDefaults = Self.unwrap(defaultResponse ?? .null)
            defaults = Self.merged(base: builtIn, overlay: serverDefaults,
                                   preservingBaseForNullKeys: Self.knownKeys)
            config = Self.merged(base: defaults, overlay: Self.unwrap(currentResponse),
                                 preservingBaseForNullKeys: Self.knownKeys)
            normalizeConfig()
            applyLibraries(librariesResponse)
            phase = .ready
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            phase = .failed(error.errorDescription ?? "加载失败")
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func applyLibraries(_ response: JSONValue?) {
        guard let response else {
            libraryOptions = []
            libraryMessage = "剧集媒体库读取失败，可保留当前范围后稍后重试。"
            return
        }
        let nested = response.deepFirst(of: "libraries", "tv_libraries", "options")
        let items = nested.array ?? response.list("libraries", "tv_libraries", "options")
        libraryOptions = items.compactMap { item in
            let value = (item.first(of: "value", "path", "id", "Id", "name", "Name")
                .displayString ?? item.displayString ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return nil }
            let label = item.first(of: "label", "name", "Name", "path", "value").displayString ?? value
            return OrganizeSelectionOption(id: value, label: label)
        }
        if libraryOptions.isEmpty {
            libraryMessage = "当前 Emby 未返回可用的剧集媒体库，留空表示全部剧集库。"
        } else {
            libraryMessage = ""
        }
    }

    private func restoreDefaults() {
        for key in Self.knownKeys {
            let value = defaults[key]
            if !value.isNull { config[key] = value }
        }
    }

    private func save() {
        normalizeConfig()
        let updated = config
        runner.run("整理配置已保存", operation: {
            let api = try session.requireAPI()
            return try await api.organize.saveConfigPreservingFields(updated)
        })
    }

    private func normalizeConfig() {
        let cron = stringValue("metadata_repair_cron", fallback: "0 2 * * *")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        config["metadata_repair_cron"] = .string(cron.isEmpty ? "0 2 * * *" : cron)

        let parseMode = stringValue("organize_parse_mode", fallback: "ffprobe").lowercased()
        config["organize_parse_mode"] = .string(
            ["ffprobe", "ffprobe_full"].contains(parseMode) ? parseMode : "ffprobe")
        config["life_monitor_start_mode"] = .string(
            stringValue("life_monitor_start_mode", fallback: "last") == "latest" ? "latest" : "last")

        config["metadata_repair_lookback_days"] = .int(
            min(max(intValue("metadata_repair_lookback_days", fallback: 60), 0), 3650))
        config["metadata_repair_workers"] = .int(
            min(max(intValue("metadata_repair_workers", fallback: 8), 1), 40))
        config["wash_tolerance_ratio"] = .double(
            min(max(doubleValue("wash_tolerance_ratio"), 0), 100))

        normalizeSelection("metadata_repair_episode_conditions", options: Self.episodeConditions)
        normalizeSelection("metadata_repair_image_conditions", options: Self.imageConditions)
        let libraries = stringArrayValue("metadata_repair_tv_libraries")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var uniqueLibraries: [String] = []
        for library in libraries where !uniqueLibraries.contains(library) {
            uniqueLibraries.append(library)
        }
        config["metadata_repair_tv_libraries"] = .array(uniqueLibraries.map(JSONValue.string))
    }

    private func normalizeSelection(_ key: String, options: [OrganizeSelectionOption]) {
        let allowed = Set(options.map(\.id))
        let values = stringArrayValue(key).filter { allowed.contains($0) }
        config[key] = .array(values.map(JSONValue.string))
    }

    private static func unwrap(_ value: JSONValue) -> JSONValue {
        for key in ["config", "data", "settings"] where value[key].object != nil {
            return value[key]
        }
        return value.object == nil ? .object([:]) : value
    }

    private static func merged(base: JSONValue, overlay: JSONValue,
                               preservingBaseForNullKeys: Set<String> = []) -> JSONValue {
        var object = base.object ?? [:]
        for (key, value) in overlay.object ?? [:] {
            if value.isNull, preservingBaseForNullKeys.contains(key), object[key] != nil { continue }
            object[key] = value
        }
        return .object(object)
    }

    fileprivate static let webDefaults: [String: JSONValue] = [
        "drive_index": 0,
        "source_cid": "0", "source_name": "根目录",
        "target_cid": "0", "target_name": "根目录",
        "failed_cid": "0", "failed_name": "根目录",
        "dedup_cid": "0", "dedup_name": "根目录",
        "wash_cid": "0", "wash_name": "根目录",
        "scrape_enabled": true, "emby_local_scrape": true,
        "scrape_nfo": true, "scrape_poster": true, "scrape_fanart": true,
        "scrape_logo": true, "scrape_banner": true, "scrape_thumb": true,
        "scrape_season_poster": true, "scrape_episode_thumb": true,
        "policy_nfo": "missing_only", "policy_poster": "missing_only",
        "policy_fanart": "missing_only", "policy_logo": "missing_only",
        "policy_banner": "missing_only", "policy_thumb": "missing_only",
        "policy_season_poster": "missing_only", "policy_episode_thumb": "missing_only",
        "metadata_repair_episode_conditions": ["no_overview", "non_chinese_overview", "default_episode_title"],
        "metadata_repair_image_conditions": ["missing_episode_thumb"],
        "metadata_repair_lookback_days": 60, "metadata_repair_workers": 8,
        "metadata_repair_tv_libraries": [], "metadata_repair_auto_enabled": true,
        "metadata_repair_cron": "0 2 * * *",
        "validation_year_enabled": true, "validation_chinese_title_enabled": true,
        "validation_poster_enabled": true, "validation_tv_episode_enabled": true,
        "life_monitor_enabled": true, "life_monitor_start_mode": "last",
        "auto_sync_strm": true, "emby_scrapers_enabled": false,
        "wash_enabled": false, "wash_by_equivalent_size": false,
        "wash_tolerance_ratio": 0.0, "organize_parse_mode": "ffprobe",
        "movie_folder_format": "{title} ({year}) {tmdb-{tmdb_id}}",
        "movie_rename_format": "{en_title}.{year}.{resource_pix}.{web_source}.{resource_type}.{resource_effect}.{video_encode}.{color_depth}.{video_effect}.{fps}.{audio_encode}-{resource_team}",
        "tv_folder_format": "{title} ({year}) {tmdb-{tmdb_id}}",
        "tv_season_folder_format": "Season {season_num}",
        "tv_episode_format": "{en_title}.{season_episode}.{year}.{resource_pix}.{web_source}.{resource_type}.{video_encode}.{color_depth}.{video_effect}.{fps}.{audio_encode}-{resource_team}"
    ]
}

/// 服务端内置默认值的完整只读说明，避免直接暴露英文 JSON 字段。
private struct OrganizeDefaultConfigView: View {
    @EnvironmentObject private var session: AppSession
    @State private var phase: Phase = .loading
    @State private var config: JSONValue = .null

    private enum Phase: Equatable {
        case loading
        case ready
        case failed(String)
    }

    private struct Group: Identifiable {
        let title: String
        let keys: [String]
        var id: String { title }
    }

    private static let groups = [
        Group(title: "115 网盘与目录", keys: [
            "drive_index", "source_name", "source_cid", "target_name", "target_cid",
            "failed_name", "failed_cid", "dedup_name", "dedup_cid", "wash_name", "wash_cid"
        ]),
        Group(title: "自动整理", keys: [
            "life_monitor_enabled", "life_monitor_start_mode", "auto_sync_strm",
            "emby_scrapers_enabled", "organize_parse_mode"
        ]),
        Group(title: "入库拦截", keys: [
            "validation_year_enabled", "validation_chinese_title_enabled",
            "validation_poster_enabled", "validation_tv_episode_enabled"
        ]),
        Group(title: "刮削内容", keys: [
            "scrape_enabled", "emby_local_scrape", "scrape_nfo", "scrape_poster",
            "scrape_fanart", "scrape_logo", "scrape_banner", "scrape_thumb",
            "scrape_season_poster", "scrape_episode_thumb"
        ]),
        Group(title: "文件覆盖策略", keys: [
            "policy_nfo", "policy_poster", "policy_fanart", "policy_logo",
            "policy_banner", "policy_thumb", "policy_season_poster", "policy_episode_thumb"
        ]),
        Group(title: "TMDb 元数据补齐", keys: [
            "metadata_repair_auto_enabled", "metadata_repair_cron",
            "metadata_repair_tv_libraries", "metadata_repair_episode_conditions",
            "metadata_repair_image_conditions", "metadata_repair_lookback_days",
            "metadata_repair_workers"
        ]),
        Group(title: "洗版策略", keys: [
            "wash_enabled", "wash_by_equivalent_size", "wash_tolerance_ratio"
        ]),
        Group(title: "重命名模板", keys: [
            "movie_folder_format", "movie_rename_format", "tv_folder_format",
            "tv_season_folder_format", "tv_episode_format"
        ])
    ]

    private static let templateKeys: Set<String> = [
        "movie_folder_format", "movie_rename_format", "tv_folder_format",
        "tv_season_folder_format", "tv_episode_format"
    ]

    var body: some View {
        Form {
            switch phase {
            case .loading:
                LoadingRow()
            case .failed(let message):
                FailureRow(message: message) { Task { await load() } }
            case .ready:
                Section {
                    Label("以下为服务端内置默认值，仅供参考", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ForEach(Self.groups) { group in
                    Section(group.title) {
                        ForEach(group.keys, id: \.self) { key in
                            configRow(key)
                        }
                    }
                }
            }
        }
        .navigationTitle("默认配置")
        .task {
            if phase == .loading { await load() }
        }
    }

    @ViewBuilder
    private func configRow(_ key: String) -> some View {
        let value = config[key]
        if let items = value.array {
            NavigationLink {
                List {
                    if items.isEmpty, key == "metadata_repair_tv_libraries" {
                        Label("全部剧集媒体库", systemImage: "checkmark.circle")
                    } else if items.isEmpty {
                        EmptyRow("未设置")
                    } else {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            Label(localizedArrayValue(item.displayString ?? "", for: key),
                                  systemImage: "checkmark.circle")
                        }
                    }
                }
                .navigationTitle(fieldLabel(key))
            } label: {
                HStack {
                    Text(fieldLabel(key))
                    Spacer()
                    Text(arraySummary(items, for: key))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else if Self.templateKeys.contains(key) {
            VStack(alignment: .leading, spacing: 6) {
                Text(fieldLabel(key))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value.displayString ?? "—")
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 3)
        } else {
            KeyValueRow(fieldLabel(key), .string(localizedValue(value, for: key)))
        }
    }

    private func localizedValue(_ value: JSONValue, for key: String) -> String {
        switch key {
        case "life_monitor_start_mode":
            return value.string == "latest" ? "仅监听最新事件" : "从上次事件继续"
        case "organize_parse_mode":
            return value.string == "ffprobe_full" ? "全量 ffprobe" : "智能 ffprobe"
        case let policy where policy.hasPrefix("policy_"):
            if value.string == "missing_only" { return "仅补缺" }
            if value.string == "overwrite" { return "覆盖现有" }
            return value.displayString ?? "—"
        case "metadata_repair_lookback_days":
            let days = value.int ?? 60
            return days == 0 ? "全部历史剧集" : "最近 \(days) 天"
        case "metadata_repair_workers":
            return "\(value.int ?? 8) 个并发"
        case "wash_tolerance_ratio":
            let ratio = value.double ?? 0
            return ratio == ratio.rounded() ? "\(Int(ratio))%" : String(format: "%.1f%%", ratio)
        default:
            return Fmt.text(value)
        }
    }

    private func localizedArrayValue(_ value: String, for key: String) -> String {
        guard key != "metadata_repair_tv_libraries" else { return value }
        switch value {
        case "no_overview": return "无简介"
        case "non_chinese_overview": return "非中文简介"
        case "default_episode_title": return "默认集标题"
        case "missing_episode_thumb": return "无图"
        default: return value
        }
    }

    private func arraySummary(_ items: [JSONValue], for key: String) -> String {
        if items.isEmpty, key == "metadata_repair_tv_libraries" { return "全部" }
        if items.isEmpty { return "未设置" }
        return "\(items.count) 项"
    }

    private func load() async {
        phase = .loading
        do {
            let api = try session.requireAPI()
            let response = try await api.organize.getDefaultConfig()
            var fetched = response
            for key in ["config", "data", "settings"] where fetched[key].object != nil {
                fetched = fetched[key]
                break
            }
            var values = OrganizeConfigView.webDefaults
            for (key, value) in fetched.object ?? [:] where !value.isNull {
                values[key] = value
            }
            config = .object(values)
            phase = .ready
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            phase = .failed(error.errorDescription ?? "加载失败")
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

private struct OrganizeSelectionOption: Identifiable, Hashable {
    let id: String
    let label: String
}

private struct OrganizeMultiSelectView: View {
    let title: String
    let options: [OrganizeSelectionOption]
    @Binding var selection: [String]
    var emptyMeansAll = false

    var body: some View {
        List {
            if emptyMeansAll {
                Button {
                    selection = []
                } label: {
                    selectionLabel("全部剧集媒体库", selected: selection.isEmpty)
                }
                .foregroundStyle(.primary)
            }

            ForEach(options) { option in
                Button {
                    toggle(option.id)
                } label: {
                    selectionLabel(option.label, selected: selection.contains(option.id))
                }
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle(title)
    }

    private func selectionLabel(_ label: String, selected: Bool) -> some View {
        HStack {
            Text(label)
            Spacer()
            if selected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
    }

    private func toggle(_ value: String) {
        if let index = selection.firstIndex(of: value) {
            selection.remove(at: index)
        } else {
            selection.append(value)
        }
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
