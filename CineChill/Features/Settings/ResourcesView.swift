import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// 封面系统入口，与 Web 端的封面设计、自动封面、备份、资源和翻译模块对应。
struct ResourcesView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "封面系统") {
            let api = try session.requireAPI()
            async let templates = Probe.json { try await api.resources.getTemplatesV2() }
            async let suites = Probe.json { try await api.resources.listSuites() }
            async let tasks = Probe.json { try await api.tasks.getTasks() }
            let (templates, suites, tasks) = await (templates, suites, tasks)
            return JSONValue.object(["templates": templates, "suites": suites, "tasks": tasks])
        } content: { value, _ in
            let templates = CoverData.templates(from: value["templates"])
            let suites = value["suites"].list("suites", "items", "data")
            let tasks = value["tasks"].list("tasks", "items", "data")

            if !templates.isEmpty {
                Section("模板预览") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(Array(templates.prefix(12).enumerated()), id: \.offset) { _, template in
                                CoverTemplatePreview(template: template)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section("功能") {
                ModuleRow(title: "封面设计",
                          subtitle: "生成媒体库封面并写回 Emby",
                          systemImage: "wand.and.rays",
                          tint: .blue) { PosterApplyView() }
                ModuleRow(title: "自动封面",
                          subtitle: "\(tasks.count) 个定时任务",
                          systemImage: "sparkles",
                          tint: .indigo) { TaskCenterView() }
                ModuleRow(title: "封面备份",
                          subtitle: "\(suites.count) 个快照套件",
                          systemImage: "archivebox",
                          tint: .purple) { SuitesView() }
                ModuleRow(title: "资源配置",
                          subtitle: "\(templates.count) 个可视化模板",
                          systemImage: "slider.horizontal.3",
                          tint: .orange) { CoverResourceConfigView() }
                ModuleRow(title: "翻译配置",
                          subtitle: "设置封面主标题与副标题",
                          systemImage: "character.book.closed",
                          tint: .teal) { TranslationsView() }
            }
        }
    }
}

/// 字体、布局、模板和登录海报资源的集中入口。
struct CoverResourceConfigView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "资源配置") {
            let api = try session.requireAPI()
            async let fonts = Probe.json { try await api.resources.getFonts() }
            async let layouts = Probe.json { try await api.resources.getLayouts() }
            async let templates = Probe.json { try await api.resources.getTemplatesV2() }
            let (fonts, layouts, templates) = await (fonts, layouts, templates)
            return .object(["fonts": fonts, "layouts": layouts, "templates": templates])
        } content: { value, _ in
            let fonts = value["fonts"].list("fonts", "items", "data")
            let layouts = CoverData.layouts(from: value["layouts"])
            let templates = CoverData.templates(from: value["templates"])

            Section("封面资源") {
                ModuleRow(title: "封面模板", subtitle: "\(templates.count) 个模板",
                          systemImage: "photo.artframe", tint: .orange) { TemplatesView() }
                ModuleRow(title: "排版布局", subtitle: "\(layouts.count) 套布局",
                          systemImage: "rectangle.3.group", tint: .teal) { LayoutsView() }
                ModuleRow(title: "字体", subtitle: "\(fonts.count) 个字体",
                          systemImage: "textformat", tint: .indigo) { FontsView() }
                ModuleRow(title: "登录页海报", subtitle: "查看登录背景图片",
                          systemImage: "photo.on.rectangle.angled", tint: .pink) { LoginPostersView() }
            }

            if !templates.isEmpty {
                Section("模板封面") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(Array(templates.prefix(16).enumerated()), id: \.offset) { _, template in
                                CoverTemplatePreview(template: template)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}

/// 兼容 v71 的分组模板结构和旧版本的扁平数组。
enum CoverData {
    static func templates(from value: JSONValue) -> [JSONValue] {
        if let raw = value["all_raw"].array, !raw.isEmpty { return raw }
        if let groups = value["data"].array {
            let flattened = groups.flatMap { group -> [JSONValue] in
                let engine = group.first(of: "layout", "engine").displayString
                return (group["presets"].array ?? []).map { preset in
                    guard let engine, preset["engine"].isNull else { return preset }
                    var normalized = preset
                    normalized["engine"] = .string(engine)
                    return normalized
                }
            }
            if !flattened.isEmpty { return flattened }
        }
        return value.list("templates", "items", "presets")
    }

    static func layouts(from value: JSONValue) -> [(key: String, value: JSONValue)] {
        if let object = value["layouts"].object {
            return object.keys.sorted().map { ($0, object[$0] ?? .null) }
        }
        return value.list("layouts", "items", "data").enumerated().map { index, layout in
            (layout.first(of: "name", "id", "engine").displayString ?? "布局 \(index + 1)", layout)
        }
    }

    static func filename(of template: JSONValue) -> String {
        template.first(of: "filename", "file", "id", "template_filename").displayString ?? ""
    }

    static func embeddedImage(in value: JSONValue) -> UIImage? {
        guard let raw = value.deepFirst(of: "image_data", "base64", "preview", "image").string,
              !raw.hasPrefix("http://"), !raw.hasPrefix("https://"), !raw.hasPrefix("/") else {
            return nil
        }
        let encoded = raw.contains(",") ? String(raw.split(separator: ",").last ?? "") : raw
        guard encoded.count > 80,
              let data = Data(base64Encoded: encoded, options: .ignoreUnknownCharacters) else { return nil }
        return UIImage(data: data)
    }

    @MainActor
    static func imageURL(in value: JSONValue, session: AppSession) -> URL? {
        let raw = value.deepFirst(of: "image_url", "preview_image", "preview_url", "cover_url",
                                  "poster_url", "thumbnail_url", "image", "cover", "poster",
                                  "thumbnail", "url", "src").string
        guard let raw, !raw.isEmpty, !raw.hasPrefix("data:"), raw.count < 4096 else { return nil }
        guard let url = session.absoluteURL(raw) else { return nil }
        guard let version = value.first(of: "image_mtime", "mtime", "updated_at").displayString,
              !version.isEmpty, var parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        var query = parts.queryItems ?? []
        query.append(URLQueryItem(name: "cover_v", value: version))
        parts.queryItems = query
        return parts.url ?? url
    }
}

struct CoverArtworkView: View {
    let value: JSONValue
    var contentMode: ContentMode = .fill
    var placeholderIcon = "photo"

    @EnvironmentObject private var session: AppSession

    var body: some View {
        Group {
            if let image = CoverData.embeddedImage(in: value) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                RemoteImage(url: CoverData.imageURL(in: value, session: session),
                            contentMode: contentMode,
                            placeholderIcon: placeholderIcon)
            }
        }
        .clipped()
    }
}

struct CoverTemplatePreview: View {
    let template: JSONValue

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CoverArtworkView(value: template, contentMode: .fill, placeholderIcon: "photo.artframe")
                .frame(width: 144, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(TemplatesView.name(of: template).isEmpty ? "未命名模板" : TemplatesView.name(of: template))
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .frame(width: 144, alignment: .leading)
            if let engine = template.first(of: "engine", "layout").displayString {
                Text(engine)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
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
            let layouts = CoverData.layouts(from: value)
            Section("布局（\(layouts.count)）") {
                if layouts.isEmpty { EmptyRow("没有布局") }
                ForEach(Array(layouts.enumerated()), id: \.offset) { _, entry in
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.3.group")
                            .font(.title3)
                            .foregroundStyle(.teal)
                            .frame(width: 44, height: 44)
                            .background(Color.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.key).font(.subheadline.weight(.medium))
                            let groups = entry.value.array ?? entry.value["groups"].array ?? []
                            let fieldCount = groups.reduce(0) { partial, group in
                                partial + (group["items"].array?.count ?? 0)
                            }
                            if fieldCount > 0 {
                                Text("\(groups.count) 组 · \(fieldCount) 个可配置参数")
                                    .font(.caption2).foregroundStyle(.secondary)
                            } else if let desc = entry.value.first(of: "description", "desc", "detail").displayString {
                                Text(desc).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                    }
                }
            }
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
            let templates = CoverData.templates(from: value)

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
                    let filename = CoverData.filename(of: template)
                    HStack(spacing: 12) {
                        CoverArtworkView(value: template, contentMode: .fill, placeholderIcon: "photo.artframe")
                            .frame(width: 112, height: 66)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        NavigationLink {
                            TemplateEditorView(template: template, reload: reload)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(name.isEmpty ? "未命名模板" : name)
                                    .font(.subheadline)
                                if let layout = template.first(of: "engine", "layout", "type", "mode").displayString {
                                    Text(layout).font(.caption2).foregroundStyle(.secondary)
                                }
                                if !filename.isEmpty {
                                    Text(filename).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                                }
                            }
                        }
                        if !filename.isEmpty {
                            Button { deleting = filename } label: {
                                Image(systemName: "trash")
                            }
                                .buttonStyle(.borderless)
                                .foregroundStyle(.red)
                                .accessibilityLabel("删除模板")
                        }
                    }
                }
            }
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
                                .object(["filename": .string(target)]))
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
        guard let object = sample?.object else {
            return .object(["filename": .string(""), "name": .string(""),
                            "engine": .string("classic"), "config": .object([:])])
        }
        var draft: [String: JSONValue] = object.mapValues { existing -> JSONValue in
            switch existing {
            case .string: return .string("")
            case .int: return .int(0)
            case .double: return .double(0)
            case .bool: return .bool(false)
            case .array: return .array([])
            default: return existing
            }
        }
        draft["filename"] = .string("")
        draft["name"] = .string("")
        draft["engine"] = .string("classic")
        draft.removeValue(forKey: "image")
        draft.removeValue(forKey: "image_mtime")
        return .object(draft)
    }
}

/// 单个模板的逐字段编辑。
struct TemplateEditorView: View {
    let reload: Reload

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var draft: JSONValue
    @State private var importingPreview = false

    init(template: JSONValue, reload: Reload) {
        self.reload = reload
        _draft = State(initialValue: template)
    }

    var body: some View {
        Form {
            Section("模板封面") {
                CoverArtworkView(value: draft, contentMode: .fit, placeholderIcon: "photo.artframe")
                    .frame(maxWidth: .infinity)
                    .frame(height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Button {
                    importingPreview = true
                } label: {
                    Label("选择预览图片", systemImage: "photo.badge.plus")
                }
                if !draft["image_data"].isNull {
                    Button(role: .destructive) {
                        draft["image_data"] = .null
                    } label: {
                        Label("移除新预览图", systemImage: "trash")
                    }
                }
            }
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
                .disabled(CoverData.filename(of: draft).isEmpty || runner.isRunning)
            }
        }
        .fileImporter(isPresented: $importingPreview, allowedContentTypes: [.image]) { result in
            guard case .success(let url) = result else { return }
            importPreview(from: url)
        }
        .navigationTitle(TemplatesView.name(of: draft).isEmpty
                         ? "模板" : TemplatesView.name(of: draft))
        .actionFeedback(runner)
    }

    private func importPreview(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), UIImage(data: data) != nil else { return }
        let ext = url.pathExtension.lowercased()
        let mime = ext == "png" ? "image/png" : (ext == "gif" ? "image/gif" : "image/jpeg")
        draft["image_data"] = .string("data:\(mime);base64,\(data.base64EncodedString())")
    }
}

/// 译名表：整体读取 / 编辑 / 保存。
struct TranslationsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        JSONConfigScreen(
            title: "翻译配置",
            note: "键是媒体库原名；值可填写文本，也可使用 title / subtitle 设置封面主标题和副标题。",
            unwrapKeys: ["translations", "data", "config"],
            load: {
                let api = try session.requireAPI()
                return try await api.resources.getTranslations()
            },
            save: { edited in
                let api = try session.requireAPI()
                return try await api.resources.saveTranslations(
                    .object(["translations": edited]))
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
    @State private var connectionLoaded = false

    var body: some View {
        RemoteList(title: "封面备份") {
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
                Text("优先读取服务器中已配置的 Emby；也可以在这里临时修改本次操作使用的连接参数。")
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
                            let time = suite.first(of: "time", "created_at", "updated_at")
                            if !time.isNull {
                                Text(Fmt.dateTime(time))
                                    .font(.caption2).foregroundStyle(.tertiary)
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
        .task {
            guard !connectionLoaded else { return }
            connectionLoaded = true
            await loadConnection()
        }
    }

    static func name(of suite: JSONValue) -> String {
        suite.first(of: "suite_name", "name", "id", "title").displayString
            ?? suite.string ?? ""
    }

    private func loadConnection() async {
        guard let api = session.api,
              let connection = await EmbyConnection.load(api: api) else { return }
        if embyURL.isEmpty { embyURL = connection.url }
        if embyKey.isEmpty { embyKey = connection.key }
        if publicHost.isEmpty { publicHost = connection.publicHost ?? "" }
    }
}

/// 套装内容（只读）。
struct SuiteContentView: View {
    let suiteName: String

    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: suiteName, cacheKey: "suite-content-\(suiteName)") {
            let api = try session.requireAPI()
            let content = try await api.resources.getSuiteContent(
                SuiteContentRequest(suiteName: suiteName))
            var covers: JSONValue = .null
            if let connection = await EmbyConnection.load(api: api) {
                covers = await Probe.json { try await api.server.getLibraryCovers(connection) }
            }
            return .object(["content": content, "covers": covers])
        } content: { value, _ in
            let content = value["content"]
            let items = content.list("images", "items", "libraries", "data", "content")
            let libraries = value["covers"].list("libraries", "items", "data", "views")
            Section("封面快照（\(items.count)）") {
                if items.isEmpty { EmptyRow("套装中没有封面图片") }
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    let id = item.first(of: "id", "item_id", "library_id").displayString ?? ""
                    HStack(spacing: 12) {
                        CoverArtworkView(value: item, contentMode: .fill, placeholderIcon: "photo")
                            .frame(width: 124, height: 74)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(libraryName(id: id, item: item, libraries: libraries))
                                .font(.subheadline.weight(.medium))
                                .lineLimit(2)
                            if !id.isEmpty {
                                Text(id).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
    }

    private func libraryName(id: String, item: JSONValue, libraries: [JSONValue]) -> String {
        if let name = item.first(of: "name", "title", "library_name").displayString, !name.isEmpty {
            return name
        }
        return libraries.first {
            $0.first(of: "id", "Id", "library_id").displayString == id
        }?.first(of: "name", "Name", "title").displayString ?? (id.isEmpty ? "未命名媒体库" : id)
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
    @State private var connectionLoaded = false

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
        .task {
            guard !connectionLoaded else { return }
            connectionLoaded = true
            await loadConnection()
        }
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

    private func loadConnection() async {
        guard let api = session.api,
              let connection = await EmbyConnection.load(api: api) else { return }
        if embyURL.isEmpty { embyURL = connection.url }
        if embyKey.isEmpty { embyKey = connection.key }
        if publicHost.isEmpty { publicHost = connection.publicHost ?? "" }
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
                        CoverArtworkView(value: posterArtwork(poster), contentMode: .fill)
                            .frame(width: 56, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
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
        }
    }

    private func posterArtwork(_ poster: JSONValue) -> JSONValue {
        if CoverData.embeddedImage(in: poster) != nil || CoverData.imageURL(in: poster, session: session) != nil {
            return poster
        }
        guard let api = try? session.requireAPI() else { return poster }
        guard let id = poster.first(of: "item_id", "id", "Id").displayString, !id.isEmpty else {
            return poster
        }
        let tag = poster.first(of: "tag", "image_tag", "primary_image_tag").displayString
        guard let url = try? api.publicResources.getLoginPosterImageURL(itemId: id, tag: tag, w: 200) else {
            return poster
        }
        var normalized = poster
        normalized["image_url"] = .string(url.absoluteString)
        return normalized
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
    @State private var libraries: [JSONValue] = []
    @State private var optionsLoaded = false
    @State private var previewSourceRequest: PreviewRequest?

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
                if !libraries.isEmpty {
                    Picker("媒体库", selection: $libraryID) {
                        Text("请选择").tag("")
                        ForEach(Array(libraries.enumerated()), id: \.offset) { _, library in
                            Text(libraryName(library)).tag(libraryIdentifier(library))
                        }
                    }
                }
                TextField("媒体库 ID", text: $libraryID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            if !libraries.isEmpty {
                Section("当前媒体库封面") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(Array(libraries.enumerated()), id: \.offset) { _, library in
                                let id = libraryIdentifier(library)
                                Button {
                                    libraryID = id
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        CoverArtworkView(value: library, contentMode: .fill,
                                                         placeholderIcon: "rectangle.stack")
                                            .frame(width: 136, height: 82)
                                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                    .stroke(libraryID == id ? Color.accentColor : Color.clear,
                                                            lineWidth: 2)
                                            }
                                        Text(libraryName(library))
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                            .frame(width: 136, alignment: .leading)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(id.isEmpty)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
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
                    generatePreview()
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

        }
        .navigationTitle("封面设计")
        .actionFeedback(runner)
        .task {
            guard !optionsLoaded else { return }
            optionsLoaded = true
            await loadOptions()
        }
        .confirmationDialog("覆盖该媒体库封面？", isPresented: $confirming, titleVisibility: .visible) {
            Button("套用", role: .destructive) {
                runner.run("已套用") {
                    let api = try session.requireAPI()
                    let current = request()
                    let imageData = previewSourceRequest == current ? previewImageData : nil
                    return try await api.resources.apply(request(imageData: imageData))
                }
            }
            Button("取消", role: .cancel) {}
        }
    }

    private func request(imageData: String? = nil) -> PreviewRequest {
        PreviewRequest(url: embyURL, key: embyKey,
                       publicHost: publicHost.isEmpty ? nil : publicHost,
                       libraryId: libraryID, config: config,
                       imageData: imageData, mode: mode)
    }

    private var previewImageData: String? {
        runner.lastResult.deepFirst(of: "image", "image_data", "preview", "base64").string
    }

    private var previewImage: UIImage? {
        guard let raw = previewImageData else { return nil }
        let cleaned = raw.contains(",") ? String(raw.split(separator: ",").last ?? "") : raw
        guard let data = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return UIImage(data: data)
    }

    /// 服务端也可能只回一个缓存 key，图片本体要从 `/api/discover/task_cover` 再取一次。
    /// 这里刻意不认裸 `key` 字段——请求里的 `key` 是 Emby API Key，不能拼进 URL。
    private var previewURL: URL? {
        if let direct = CoverData.imageURL(in: runner.lastResult, session: session) {
            return direct
        }
        guard let key = runner.lastResult
            .deepFirst(of: "cover_key", "preview_key", "cache_key", "task_cover_key").displayString,
              !key.isEmpty else { return nil }
        return try? session.api?.discover.taskCoverPreviewURL(key: key)
    }

    private func generatePreview() {
        let payload = request()
        runner.run(nil, operation: {
            let api = try session.requireAPI()
            return try await api.resources.preview(payload)
        }, onSuccess: {
            previewSourceRequest = payload
        })
    }

    private func loadOptions() async {
        guard let api = session.api,
              let connection = await EmbyConnection.load(api: api) else { return }
        if embyURL.isEmpty { embyURL = connection.url }
        if embyKey.isEmpty { embyKey = connection.key }
        if publicHost.isEmpty { publicHost = connection.publicHost ?? "" }
        let covers = await Probe.json { try await api.server.getLibraryCovers(connection) }
        libraries = covers.list("libraries", "items", "data", "views")
        if libraryID.isEmpty { libraryID = libraries.first.map(libraryIdentifier) ?? "" }
    }

    private func libraryIdentifier(_ library: JSONValue) -> String {
        library.first(of: "id", "Id", "library_id", "LibraryId").displayString ?? ""
    }

    private func libraryName(_ library: JSONValue) -> String {
        library.first(of: "name", "Name", "title", "library_name").displayString
            ?? libraryIdentifier(library)
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
            let templates = CoverData.templates(from: value)
            Section("模板（\(templates.count)）") {
                if templates.isEmpty { EmptyRow("没有模板") }
                ForEach(Array(templates.enumerated()), id: \.offset) { _, template in
                    Button {
                        config = Self.parameters(of: template)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            CoverArtworkView(value: template, contentMode: .fill,
                                             placeholderIcon: "photo.artframe")
                                .frame(width: 104, height: 62)
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(TemplatesView.name(of: template).isEmpty
                                     ? "未命名模板" : TemplatesView.name(of: template))
                                    .foregroundStyle(.primary)
                                if let engine = template.first(of: "engine", "layout").displayString {
                                    Text(engine).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }

    /// 模板可能把参数包在 config/params 里，也可能直接铺平。
    static func parameters(of template: JSONValue) -> JSONValue {
        for key in ["config", "params", "settings", "options"] where template[key].object != nil {
            var parameters = template[key]
            if parameters["engine"].isNull,
               let engine = template.first(of: "engine", "layout").displayString {
                parameters["engine"] = .string(engine)
            }
            return parameters
        }
        return template
    }
}
