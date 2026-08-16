import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// 素材与模板总览：字体、布局、模板、译名、套装备份、登录海报、海报套用。
struct ResourcesView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "素材与模板") {
            let api = try session.requireAPI()
            let fonts = await Probe.json { try await api.resources.getFonts() }
            let layouts = await Probe.json { try await api.resources.getLayouts() }
            let templates = await Probe.json { try await api.resources.getTemplatesV2() }
            let suites = await Probe.json { try await api.resources.listSuites() }
            return JSONValue.object(["fonts": fonts, "layouts": layouts,
                                     "templates": templates, "suites": suites])
        } content: { value, _ in
            let fonts = value["fonts"].list("fonts", "items", "data")
            let layouts = value["layouts"].list("layouts", "items", "data")
            let templates = value["templates"].list("templates", "items", "data")
            let suites = value["suites"].list("suites", "items", "data")

            Section("素材") {
                ModuleRow(title: "字体",
                          subtitle: "\(fonts.count) 个可用字体",
                          systemImage: "textformat",
                          tint: .indigo) { FontsView() }
                ModuleRow(title: "布局",
                          subtitle: "\(layouts.count) 套排版布局",
                          systemImage: "square.grid.2x2",
                          tint: .teal) { LayoutsView() }
                ModuleRow(title: "模板",
                          subtitle: "\(templates.count) 个海报模板",
                          systemImage: "photo.artframe",
                          tint: .orange) { TemplatesView() }
            }

            Section("文本与备份") {
                ModuleRow(title: "译名表",
                          subtitle: "媒体库名称翻译",
                          systemImage: "character.book.closed",
                          tint: .brown) { TranslationsView() }
                ModuleRow(title: "套装备份",
                          subtitle: "\(suites.count) 个套装",
                          systemImage: "shippingbox",
                          tint: .purple) { SuitesView() }
            }

            Section("海报") {
                ModuleRow(title: "登录页海报",
                          subtitle: "登录背景取图来源",
                          systemImage: "rectangle.on.rectangle",
                          tint: .pink) { LoginPostersView() }
                ModuleRow(title: "预览与套用",
                          subtitle: "生成媒体库封面并写回 Emby",
                          systemImage: "wand.and.rays",
                          tint: .blue) { PosterApplyView() }
            }

            Section { JSONInspector(value: value) }
        }
    }
}

/// 字体管理：上传、查看、删除。
struct FontsView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var importing = false
    @State private var deleting: String?

    var body: some View {
        RemoteList(title: "字体") {
            let api = try session.requireAPI()
            return try await api.resources.getFonts()
        } content: { value, reload in
            Section {
                Button {
                    importing = true
                } label: {
                    Label("从「文件」上传字体", systemImage: "arrow.up.doc")
                }
            } footer: {
                Text("支持 ttf / otf / ttc。字体只上传到你自己的 CineChill 服务器，用于海报文字渲染。")
            }

            let fonts = value.list("fonts", "items", "data")
            Section("已安装（\(fonts.count)）") {
                if fonts.isEmpty { EmptyRow("没有字体") }
                ForEach(Array(fonts.enumerated()), id: \.offset) { _, font in
                    let name = Self.name(of: font)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name).font(.subheadline).lineLimit(1)
                            if let size = font.first(of: "size", "bytes").double {
                                Text(Fmt.bytes(size))
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        if !name.isEmpty {
                            Button("删除") { deleting = name }
                                .font(.caption)
                                .buttonStyle(.borderless)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            Section { JSONInspector(value: value) }
                .fileImporter(isPresented: $importing,
                              allowedContentTypes: [.font, .data]) { result in
                    switch result {
                    case .success(let url):
                        upload(url, reload: reload)
                    case .failure:
                        break
                    }
                }
                .confirmationDialog("删除字体？",
                                    isPresented: Binding(get: { deleting != nil },
                                                         set: { if !$0 { deleting = nil } }),
                                    titleVisibility: .visible) {
                    Button("删除", role: .destructive) {
                        guard let target = deleting else { return }
                        deleting = nil
                        runner.run("已删除", operation: {
                            let api = try session.requireAPI()
                            return try await api.resources.deleteFont(
                                .object(["name": .string(target),
                                         "filename": .string(target),
                                         "font": .string(target)]))
                        }, onSuccess: { await reload() })
                    }
                    Button("取消", role: .cancel) { deleting = nil }
                }
        }
        .actionFeedback(runner)
    }

    private func upload(_ url: URL, reload: Reload) {
        runner.run("已上传", operation: {
            let api = try session.requireAPI()
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            return try await api.resources.uploadFont(fileData: data,
                                                     filename: url.lastPathComponent)
        }, onSuccess: {
            await reload()
        })
    }

    static func name(of font: JSONValue) -> String {
        font.first(of: "name", "filename", "file", "font").displayString
            ?? font.string ?? ""
    }
}

/// 布局（只读）。
struct LayoutsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "布局") {
            let api = try session.requireAPI()
            return try await api.resources.getLayouts()
        } content: { value, _ in
            let layouts = value.list("layouts", "items", "data")
            Section("布局（\(layouts.count)）") {
                if layouts.isEmpty { EmptyRow("没有布局") }
                ForEach(Array(layouts.enumerated()), id: \.offset) { _, layout in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(layout.first(of: "name", "label", "id").displayString
                             ?? layout.string ?? "—")
                            .font(.subheadline)
                        if let desc = layout.first(of: "description", "desc", "detail").displayString {
                            Text(desc).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                }
            }
            Section { JSONInspector(value: value) }
        }
    }
}

/// 海报模板：列表 / 编辑 / 新建 / 删除。
struct TemplatesView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var deleting: String?

    var body: some View {
        RemoteList(title: "模板") {
            let api = try session.requireAPI()
            return try await api.resources.getTemplatesV2()
        } content: { value, reload in
            let templates = value.list("templates", "items", "data")

            Section {
                NavigationLink {
                    TemplateEditorView(template: Self.blank(like: templates.first),
                                       reload: reload)
                } label: {
                    Label("新建模板", systemImage: "plus.circle")
                }
            } footer: {
                Text("模板字段由服务端定义，这里按返回的结构逐字段编辑，保存后整体写回。")
            }

            Section("模板（\(templates.count)）") {
                if templates.isEmpty { EmptyRow("没有模板") }
                ForEach(Array(templates.enumerated()), id: \.offset) { _, template in
                    let name = Self.name(of: template)
                    HStack {
                        NavigationLink {
                            TemplateEditorView(template: template, reload: reload)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(name.isEmpty ? "未命名模板" : name)
                                    .font(.subheadline)
                                if let layout = template.first(of: "layout", "type", "mode").displayString {
                                    Text(layout).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                        if !name.isEmpty {
                            Button("删除") { deleting = name }
                                .font(.caption)
                                .buttonStyle(.borderless)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            Section { JSONInspector(value: value) }
                .confirmationDialog("删除模板？",
                                    isPresented: Binding(get: { deleting != nil },
                                                         set: { if !$0 { deleting = nil } }),
                                    titleVisibility: .visible) {
                    Button("删除", role: .destructive) {
                        guard let target = deleting else { return }
                        deleting = nil
                        runner.run("已删除", operation: {
                            let api = try session.requireAPI()
                            return try await api.resources.deleteTemplate(
                                .object(["name": .string(target),
                                         "id": .string(target),
                                         "template_name": .string(target)]))
                        }, onSuccess: { await reload() })
                    }
                    Button("取消", role: .cancel) { deleting = nil }
                }
        }
        .actionFeedback(runner)
    }

    static func name(of template: JSONValue) -> String {
        template.first(of: "name", "id", "title", "template_name").displayString
            ?? template.string ?? ""
    }

    /// 用已有模板的字段结构生成一个空模板，避免凭空猜服务端需要哪些键。
    static func blank(like sample: JSONValue?) -> JSONValue {
        guard let object = sample?.object else { return .object(["name": .string("")]) }
        return .object(object.mapValues { existing in
            switch existing {
            case .string: return .string("")
            case .int: return .int(0)
            case .double: return .double(0)
            case .bool: return .bool(false)
            case .array: return .array([])
            default: return existing
            }
        })
    }
}

/// 单个模板的逐字段编辑。
struct TemplateEditorView: View {
    let reload: Reload

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var draft: JSONValue

    init(template: JSONValue, reload: Reload) {
        self.reload = reload
        _draft = State(initialValue: template)
    }

    var body: some View {
        Form {
            Section("字段") {
                JSONObjectEditor(value: $draft)
            }
            Section {
                Button {
                    runner.run("已保存", operation: {
                        let api = try session.requireAPI()
                        return try await api.resources.saveTemplate(draft)
                    }, onSuccess: { await reload() })
                } label: {
                    Label("保存模板", systemImage: "square.and.arrow.down")
                }
                JSONInspector(value: draft, title: "当前草稿")
            }
        }
        .navigationTitle(TemplatesView.name(of: draft).isEmpty
                         ? "模板" : TemplatesView.name(of: draft))
        .actionFeedback(runner)
    }
}

/// 译名表：整体读取 / 编辑 / 保存。
struct TranslationsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        JSONConfigScreen(
            title: "译名表",
            note: "键是原始名称，值是显示名称。海报与媒体库标题会按这张表替换。",
            unwrapKeys: ["translations", "data", "config"],
            load: {
                let api = try session.requireAPI()
                return try await api.resources.getTranslations()
            },
            save: { edited in
                let api = try session.requireAPI()
                return try await api.resources.saveTranslations(edited)
            })
    }
}

/// 套装备份：列出 / 创建 / 查看内容 / 还原 / 删除。
struct SuitesView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @AppStorage("resources.emby_url") private var embyURL = ""
    @AppStorage("resources.public_host") private var publicHost = ""
    @State private var embyKey = ""
    @State private var suiteName = ""
    @State private var deleting: String?

    var body: some View {
        RemoteList(title: "套装备份") {
            let api = try session.requireAPI()
            return try await api.resources.listSuites()
        } content: { value, reload in
            Section {
                TextField("Emby 地址", text: $embyURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                SecureField("Emby API Key", text: $embyKey)
                TextField("外网地址（可选）", text: $publicHost)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("目标 Emby")
            } footer: {
                Text("地址会记在本机，API Key 只保存在当前页面、随请求发给你自己的 CineChill 服务器，不会写入本地存储。")
            }

            Section("新建套装") {
                TextField("套装名称", text: $suiteName)
                Button {
                    runner.run("已创建", operation: {
                        let api = try session.requireAPI()
                        return try await api.resources.createSuite(
                            SuiteBackupRequest(url: embyURL, key: embyKey,
                                               publicHost: publicHost.isEmpty ? nil : publicHost,
                                               suiteName: suiteName))
                    }, onSuccess: {
                        suiteName = ""
                        await reload()
                    })
                } label: {
                    Label("备份当前封面为套装", systemImage: "square.and.arrow.down.on.square")
                }
                .disabled(embyURL.isEmpty || embyKey.isEmpty || suiteName.isEmpty)
            }

            let suites = value.list("suites", "items", "data")
            Section("套装（\(suites.count)）") {
                if suites.isEmpty { EmptyRow("没有套装") }
                ForEach(Array(suites.enumerated()), id: \.offset) { _, suite in
                    let name = Self.name(of: suite)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(name.isEmpty ? "未命名套装" : name)
                                .font(.subheadline)
                            Spacer()
                            if let count = suite.first(of: "count", "items", "total").displayString {
                                Text(count).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                        if !name.isEmpty {
                            HStack(spacing: 14) {
                                NavigationLink("查看内容") {
                                    SuiteContentView(suiteName: name)
                                }
                                NavigationLink("还原") {
                                    SuiteRestoreView(suiteName: name)
                                }
                                Button("删除") { deleting = name }
                                    .foregroundStyle(.red)
                            }
                            .font(.caption)
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            Section { JSONInspector(value: value) }
                .confirmationDialog("删除套装？",
                                    isPresented: Binding(get: { deleting != nil },
                                                         set: { if !$0 { deleting = nil } }),
                                    titleVisibility: .visible) {
                    Button("删除", role: .destructive) {
                        guard let target = deleting else { return }
                        deleting = nil
                        runner.run("已删除", operation: {
                            let api = try session.requireAPI()
                            return try await api.resources.deleteSuite(
                                .object(["suite_name": .string(target),
                                         "name": .string(target)]))
                        }, onSuccess: { await reload() })
                    }
                    Button("取消", role: .cancel) { deleting = nil }
                }
        }
        .actionFeedback(runner)
    }

    static func name(of suite: JSONValue) -> String {
        suite.first(of: "suite_name", "name", "id", "title").displayString
            ?? suite.string ?? ""
    }
}

/// 套装内容（只读）。
struct SuiteContentView: View {
    let suiteName: String

    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: suiteName) {
            let api = try session.requireAPI()
            return try await api.resources.getSuiteContent(
                SuiteContentRequest(suiteName: suiteName))
        } content: { value, _ in
            let items = value.list("items", "libraries", "data", "content")
            Section("条目（\(items.count)）") {
                if items.isEmpty { EmptyRow("套装为空") }
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.first(of: "name", "title", "library_name").displayString
                             ?? item.string ?? "—")
                            .font(.subheadline)
                        if let id = item.first(of: "id", "item_id", "library_id").displayString {
                            Text(id).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            Section("字段") { JSONFieldList(value: value, skipKeys: ["items", "content"]) }
            Section { JSONInspector(value: value) }
        }
    }
}

/// 套装还原到指定媒体库。
struct SuiteRestoreView: View {
    let suiteName: String

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @AppStorage("resources.emby_url") private var embyURL = ""
    @AppStorage("resources.public_host") private var publicHost = ""
    @State private var embyKey = ""
    @State private var targetIDs = ""
    @State private var confirming = false

    var body: some View {
        Form {
            Section("目标 Emby") {
                TextField("Emby 地址", text: $embyURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                SecureField("Emby API Key", text: $embyKey)
                TextField("外网地址（可选）", text: $publicHost)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section {
                TextField("媒体库 ID（逗号分隔，留空表示全部）", text: $targetIDs)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    confirming = true
                } label: {
                    Label("还原套装「\(suiteName)」", systemImage: "arrow.uturn.backward.circle")
                }
                .disabled(embyURL.isEmpty || embyKey.isEmpty)
            } footer: {
                Text("还原会覆盖目标媒体库当前的封面图，操作不可撤销。")
            }

            if runner.lastResult.isNull == false {
                Section("返回") { JSONFieldList(value: runner.lastResult) }
            }
        }
        .navigationTitle("还原")
        .actionFeedback(runner)
        .confirmationDialog("覆盖目标媒体库封面？", isPresented: $confirming, titleVisibility: .visible) {
            Button("还原", role: .destructive) {
                runner.run("已还原") {
                    let api = try session.requireAPI()
                    return try await api.resources.restoreSuite(
                        SuiteRestoreRequest(url: embyURL, key: embyKey,
                                            publicHost: publicHost.isEmpty ? nil : publicHost,
                                            suiteName: suiteName,
                                            targetIds: Self.ids(from: targetIDs)))
                }
            }
            Button("取消", role: .cancel) {}
        }
    }

    static func ids(from text: String) -> [JSONValue] {
        text.split(whereSeparator: { ",，; ".contains($0) })
            .map { JSONValue.string(String($0).trimmingCharacters(in: .whitespaces)) }
            .filter { ($0.string ?? "").isEmpty == false }
    }
}

/// 登录页海报来源。
struct LoginPostersView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "登录页海报") {
            let api = try session.requireAPI()
            return try await api.publicResources.getLoginPosters()
        } content: { value, _ in
            let posters = value.list("posters", "items", "data")
            Section("海报（\(posters.count)）") {
                if posters.isEmpty { EmptyRow("没有可用海报") }
                ForEach(Array(posters.prefix(60).enumerated()), id: \.offset) { _, poster in
                    HStack(spacing: 12) {
                        if let url = posterURL(poster) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fill)
                                case .failure:
                                    Image(systemName: "photo").foregroundStyle(.tertiary)
                                default:
                                    ProgressView()
                                }
                            }
                            .frame(width: 56, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(poster.first(of: "name", "title", "Name").displayString ?? "—")
                                .font(.subheadline).lineLimit(2)
                            if let id = poster.first(of: "item_id", "id", "Id").displayString {
                                Text(id).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            Section { JSONInspector(value: value) }
        }
    }

    private func posterURL(_ poster: JSONValue) -> URL? {
        guard let api = try? session.requireAPI() else { return nil }
        guard let id = poster.first(of: "item_id", "id", "Id").displayString, !id.isEmpty else {
            return nil
        }
        let tag = poster.first(of: "tag", "image_tag", "primary_image_tag").displayString
        return try? api.publicResources.getLoginPosterImageURL(itemId: id, tag: tag, w: 200)
    }
}

/// 海报预览与套用。
struct PosterApplyView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @AppStorage("resources.emby_url") private var embyURL = ""
    @AppStorage("resources.public_host") private var publicHost = ""
    @State private var embyKey = ""
    @State private var libraryID = ""
    @State private var mode = "random"
    @State private var config: JSONValue = .object([:])
    @State private var confirming = false

    var body: some View {
        Form {
            Section("目标 Emby") {
                TextField("Emby 地址", text: $embyURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                SecureField("Emby API Key", text: $embyKey)
                TextField("外网地址（可选）", text: $publicHost)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("媒体库 ID", text: $libraryID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section {
                Picker("取图模式", selection: $mode) {
                    Text("随机").tag("random")
                    Text("最新").tag("latest")
                    Text("最热").tag("popular")
                }
                NavigationLink {
                    JSONObjectEditorScreen(title: "模板参数", value: $config)
                } label: {
                    HStack {
                        Text("模板参数")
                        Spacer()
                        Text("\(config.sortedPairs.count) 字段")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    PosterConfigPickerView(config: $config)
                } label: {
                    Label("从已有模板载入参数", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("生成参数")
            } footer: {
                Text("模板参数就是服务端模板里的字段，可以先从已有模板载入再局部调整。")
            }

            Section {
                Button {
                    runner.run(nil) {
                        let api = try session.requireAPI()
                        return try await api.resources.preview(request())
                    }
                } label: {
                    Label("生成预览", systemImage: "eye")
                }
                .disabled(embyURL.isEmpty || embyKey.isEmpty || libraryID.isEmpty)
                Button {
                    confirming = true
                } label: {
                    Label("套用到媒体库", systemImage: "checkmark.seal")
                }
                .disabled(embyURL.isEmpty || embyKey.isEmpty || libraryID.isEmpty)
            }

            if let image = previewImage {
                Section("预览") {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            } else if let url = previewURL {
                Section("预览") {
                    RemoteImage(url: url, contentMode: .fit, placeholderIcon: "photo")
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            if runner.lastResult.isNull == false {
                Section("返回") {
                    JSONFieldList(value: runner.lastResult,
                                  skipKeys: ["image", "image_data", "preview", "base64"])
                    JSONInspector(value: runner.lastResult)
                }
            }
        }
        .navigationTitle("预览与套用")
        .actionFeedback(runner)
        .confirmationDialog("覆盖该媒体库封面？", isPresented: $confirming, titleVisibility: .visible) {
            Button("套用", role: .destructive) {
                runner.run("已套用") {
                    let api = try session.requireAPI()
                    return try await api.resources.apply(request())
                }
            }
            Button("取消", role: .cancel) {}
        }
    }

    private func request() -> PreviewRequest {
        PreviewRequest(url: embyURL, key: embyKey,
                       publicHost: publicHost.isEmpty ? nil : publicHost,
                       libraryId: libraryID, config: config, mode: mode)
    }

    private var previewImage: UIImage? {
        guard let raw = runner.lastResult
            .deepFirst(of: "image", "image_data", "preview", "base64").string else { return nil }
        let cleaned = raw.contains(",") ? String(raw.split(separator: ",").last ?? "") : raw
        guard let data = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return UIImage(data: data)
    }

    /// 服务端也可能只回一个缓存 key，图片本体要从 `/api/discover/task_cover` 再取一次。
    /// 这里刻意不认裸 `key` 字段——请求里的 `key` 是 Emby API Key，不能拼进 URL。
    private var previewURL: URL? {
        guard let key = runner.lastResult
            .deepFirst(of: "cover_key", "preview_key", "cache_key", "task_cover_key").displayString,
              !key.isEmpty else { return nil }
        return try? session.api?.discover.taskCoverPreviewURL(key: key)
    }
}

/// 从服务端模板列表里挑一个，把它的字段灌进预览参数。
struct PosterConfigPickerView: View {
    @Binding var config: JSONValue

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        RemoteList(title: "选择模板") {
            let api = try session.requireAPI()
            return try await api.resources.getTemplatesV2()
        } content: { value, _ in
            let templates = value.list("templates", "items", "data")
            Section("模板（\(templates.count)）") {
                if templates.isEmpty { EmptyRow("没有模板") }
                ForEach(Array(templates.enumerated()), id: \.offset) { _, template in
                    Button {
                        config = Self.parameters(of: template)
                        dismiss()
                    } label: {
                        HStack {
                            Text(TemplatesView.name(of: template).isEmpty
                                 ? "未命名模板" : TemplatesView.name(of: template))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            Section { JSONInspector(value: value) }
        }
    }

    /// 模板可能把参数包在 config/params 里，也可能直接铺平。
    static func parameters(of template: JSONValue) -> JSONValue {
        for key in ["config", "params", "settings", "options"] where template[key].object != nil {
            return template[key]
        }
        return template
    }
}
