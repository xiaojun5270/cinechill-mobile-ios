import SwiftUI

public extension Binding where Value == JSONValue {
    func child(_ key: String) -> Binding<JSONValue> {
        Binding(get: { wrappedValue[key] }, set: { wrappedValue[key] = $0 })
    }

    func element(_ index: Int) -> Binding<JSONValue> {
        Binding(get: { wrappedValue[index] }, set: { wrappedValue[index] = $0 })
    }

    var asString: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue.displayString ?? "" },
            set: { newValue in
                self.wrappedValue = newValue.isEmpty ? .string("") : .string(newValue)
            }
        )
    }

    var asBool: Binding<Bool> {
        Binding<Bool>(
            get: { self.wrappedValue.bool ?? false },
            set: { newValue in self.wrappedValue = .bool(newValue) }
        )
    }

    var asIntText: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue.int.map(String.init) ?? "" },
            set: { newValue in
                self.wrappedValue = Int(newValue).map(JSONValue.int) ?? .int(0)
            }
        )
    }

    var asDoubleText: Binding<String> {
        Binding<String>(
            get: {
                guard let d = self.wrappedValue.double else { return "" }
                return d == d.rounded() ? String(Int(d)) : String(d)
            },
            set: { newValue in
                if let d = Double(newValue), d.isFinite {
                    self.wrappedValue = .double(d)
                } else {
                    self.wrappedValue = .double(0)
                }
            }
        )
    }
}

/// 判断字段名是否为敏感信息，决定是否用密文输入框。
func isSecretKey(_ key: String) -> Bool {
    let lower = key.lowercased()
    return ["password", "passwd", "secret", "token", "cookie", "api_key", "apikey",
            "tmdb_key", "app_secret", "private", "credential", "bot_token", "api_hash"]
        .contains { lower.contains($0) }
}

func fieldLabel(_ key: String) -> String {
    ConfigLabels.chinese[key] ?? key
}

/// 常见配置字段的中文名。命中即显示中文，未命中回落到原始键名，
/// 这样即便服务端新增字段也不会丢失可编辑性。
enum ConfigLabels {
    static let chinese: [String: String] = [
        "enabled": "启用",
        "name": "名称",
        "cron": "定时表达式",
        "url": "地址",
        "key": "密钥",
        "public_host": "外网地址",
        "proxy_port": "代理端口",
        "cookie": "Cookie",
        "notify": "通知",
        "max_retries": "最大重试次数",
        "retry_interval": "重试间隔",
        "history_days": "历史保留天数",
        "mode": "模式",
        "model": "模型",
        "base_url": "接口地址",
        "api_key": "API Key",
        "proxy_enabled": "启用代理",
        "drive_index": "网盘序号",
        "source_cid": "源目录 CID",
        "source_name": "源目录",
        "target_cid": "目标目录 CID",
        "target_name": "目标目录",
        "failed_cid": "失败目录 CID",
        "failed_name": "失败目录",
        "dedup_cid": "去重目录 CID",
        "dedup_name": "去重目录",
        "wash_cid": "洗版目录 CID",
        "wash_name": "洗版目录",
        "scrape_enabled": "启用刮削",
        "emby_local_scrape": "使用 Emby 本地刮削",
        "scrape_nfo": "刮削 NFO",
        "scrape_poster": "刮削海报",
        "scrape_fanart": "刮削背景图",
        "scrape_logo": "刮削 Logo",
        "scrape_banner": "刮削横幅",
        "scrape_thumb": "刮削缩略图",
        "scrape_season_poster": "刮削季海报",
        "scrape_episode_thumb": "刮削剧集缩略图",
        "policy_nfo": "NFO 覆盖策略",
        "policy_poster": "海报覆盖策略",
        "policy_fanart": "背景图覆盖策略",
        "policy_logo": "Logo 覆盖策略",
        "policy_banner": "横幅覆盖策略",
        "policy_thumb": "缩略图覆盖策略",
        "policy_season_poster": "季海报覆盖策略",
        "policy_episode_thumb": "剧集缩略图覆盖策略",
        "metadata_repair_auto_enabled": "自动运行元数据补齐",
        "metadata_repair_cron": "元数据补齐 Cron",
        "metadata_repair_episode_conditions": "剧集 NFO 修复条件",
        "metadata_repair_image_conditions": "剧集图片修复条件",
        "metadata_repair_lookback_days": "剧集刷新回溯天数",
        "metadata_repair_workers": "整理后本地补齐并发数",
        "metadata_repair_tv_libraries": "元数据补齐剧集库范围",
        "validation_year_enabled": "拦截无有效年份",
        "validation_chinese_title_enabled": "拦截无中文名",
        "validation_poster_enabled": "拦截无封面",
        "validation_tv_episode_enabled": "拦截 TMDb 季集不匹配",
        "life_monitor_enabled": "115 事件监听",
        "life_monitor_start_mode": "首次监听位置",
        "auto_sync_strm": "整理完成自动同步 STRM",
        "emby_scrapers_enabled": "启用 Emby 刮削器",
        "wash_enabled": "启用洗版",
        "wash_by_equivalent_size": "按等效体积洗版",
        "wash_tolerance_ratio": "洗版体积容差",
        "wash_reserved_1": "洗版兼容参数 1",
        "wash_reserved_2": "洗版兼容参数 2",
        "organize_parse_mode": "媒体信息解析模式",
        "movie_folder_format": "电影目录模板",
        "movie_rename_format": "电影文件名模板",
        "tv_folder_format": "剧集目录模板",
        "tv_season_folder_format": "季目录模板",
        "tv_episode_format": "剧集文件名模板",
        "sync_emby_library": "同步 Emby 媒体库",
        "emby_server_idx": "Emby 服务器序号",
        "emby_library_level": "媒体库合并方式",
        "levels": "分类层级",
        "movie": "电影",
        "tv": "剧集",
        "local_folder": "本地目录",
        "target_path": "目标路径",
        "watch_mode": "监控模式",
        "remote_path": "远端路径",
        "local_path": "本地路径",
        "strm_url_base": "STRM 地址前缀",
        "min_video_size_mb": "最小视频体积(MB)",
        "video_exts_str": "视频扩展名",
        "download_auxiliary": "下载辅助文件",
        "clear_recycle_bin": "清空回收站",
        "recycle_code": "回收站密码",
        "upload_dir": "上传目录",
        "enable_sync": "启用同步",
        "auto_delete": "自动删除",
        "delete_cron": "删除定时",
        "bot_token": "Bot Token",
        "chat_id": "Chat ID",
        "corp_id": "企业 ID",
        "app_secret": "应用密钥",
        "agent_id": "AgentId",
        "proxy_url": "代理地址",
        "tmdb_key": "TMDB API Key",
        "douban_cookie": "豆瓣 Cookie",
        "app_public_base_url": "公开访问地址",
        "log_level": "日志级别",
        "channel_name": "渠道名称",
        "account_monitor_enabled": "账号监听",
        "api_id": "API ID",
        "api_hash": "API Hash",
        "phone": "手机号",
        "engine": "引擎",
        "preset": "预设",
        "delete_sync_enabled": "同步删除",
        "mp_url": "MoviePilot 地址",
        "mp_username": "MoviePilot 账号",
        "mp_password": "MoviePilot 密码",
        "source_root": "源站根地址",
        "link_root": "链接根地址",
        "rss_url": "RSS 地址",
        "media_type": "媒体类型",
        "subscription_target": "订阅目标",
        "content_type": "内容类型",
        "target_server_idx": "目标服务器序号",
        "sync_library_missing_to_mp": "缺集同步到 MoviePilot",
        "preset_filename": "预设文件",
        "auto_include_new_libraries": "自动纳入新媒体库",
        "verify_concurrency": "校验并发",
        "rapid_concurrency": "秒传并发",
        "upload_concurrency": "上传并发",
        "public_base_url": "对外基础地址",
        "library_enabled": "启用媒体库",
        "transfer_mode": "转存模式",
        "aiying_enabled": "启用爱影",
        "aiying_tg_id": "爱影 TG ID",
        "aiying_chill_token": "爱影 Token",
        "media_identity_enabled": "媒体识别",
        "tmdb_episode_verify_enabled": "TMDB 集数校验",
        "assistant_tools_enabled": "助手工具调用",
        "assistant_context_compression_enabled": "上下文压缩",
        "assistant_context_compression_threshold": "压缩触发阈值",
        "assistant_context_target_ratio": "压缩目标比例",
        "assistant_context_protect_recent": "保护最近条数",
        "assistant_context_protect_head": "保护开头条数",
        "model_context_length": "模型上下文长度",
        "robot_prompt": "机器人提示词",
        "user_prompt": "用户提示词",
        "notes_prompt": "备注提示词",
    ]
}

/// 递归的 JSON 对象编辑器：标量直接编辑，对象/数组下钻。
/// 用它可以忠实覆盖服务端的全部配置字段，而不必为每个模块手写表单。
public struct JSONObjectEditor: View {
    @Binding var value: JSONValue
    var secretsRevealed: Bool = false

    public init(value: Binding<JSONValue>, secretsRevealed: Bool = false) {
        self._value = value
        self.secretsRevealed = secretsRevealed
    }

    public var body: some View {
        ForEach(value.sortedPairs, id: \.key) { pair in
            row(key: pair.key, current: pair.value)
        }
    }

    @ViewBuilder
    private func row(key: String, current: JSONValue) -> some View {
        let binding = $value.child(key)
        switch current {
        case .bool:
            Toggle(fieldLabel(key), isOn: binding.asBool)
        case .int:
            HStack {
                Text(fieldLabel(key))
                Spacer()
                TextField("0", text: binding.asIntText)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 140)
            }
        case .double:
            HStack {
                Text(fieldLabel(key))
                Spacer()
                TextField("0", text: binding.asDoubleText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 140)
            }
        case .string(let text):
            if isSecretKey(key), !secretsRevealed {
                SecureField(fieldLabel(key), text: binding.asString)
            } else if text.count > 60 || text.contains("\n") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fieldLabel(key)).font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: binding.asString)
                        .frame(minHeight: 96)
                        .font(.system(.footnote, design: .monospaced))
                }
            } else {
                HStack {
                    Text(fieldLabel(key))
                    Spacer()
                    TextField("", text: binding.asString)
                        .multilineTextAlignment(.trailing)
                }
            }
        case .null:
            HStack {
                Text(fieldLabel(key))
                Spacer()
                TextField("空", text: binding.asString)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
        case .array(let items):
            NavigationLink {
                AnyView(JSONArrayEditorScreen(title: fieldLabel(key), value: binding))
            } label: {
                HStack {
                    Text(fieldLabel(key))
                    Spacer()
                    Text("\(items.count) 项").font(.caption).foregroundStyle(.secondary)
                }
            }
        case .object(let dict):
            NavigationLink {
                AnyView(JSONObjectEditorScreen(title: fieldLabel(key), value: binding))
            } label: {
                HStack {
                    Text(fieldLabel(key))
                    Spacer()
                    Text("\(dict.count) 字段").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

public struct JSONObjectEditorScreen: View {
    let title: String
    @Binding var value: JSONValue

    public init(title: String, value: Binding<JSONValue>) {
        self.title = title
        self._value = value
    }

    public var body: some View {
        Form {
            JSONObjectEditor(value: $value)
        }
        .navigationTitle(title)
    }
}

public struct JSONArrayEditorScreen: View {
    let title: String
    @Binding var value: JSONValue

    public init(title: String, value: Binding<JSONValue>) {
        self.title = title
        self._value = value
    }

    private var items: [JSONValue] { value.array ?? [] }

    public var body: some View {
        List {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if item.object != nil {
                    NavigationLink {
                        AnyView(JSONObjectEditorScreen(
                            title: item.first(of: "name", "title", "id").displayString ?? "第 \(index + 1) 项",
                            value: $value.element(index)))
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.first(of: "name", "title", "id").displayString ?? "第 \(index + 1) 项")
                            if let detail = item.first(of: "url", "path", "remote_path", "rss_url").displayString {
                                Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                    }
                } else {
                    TextField("值", text: $value.element(index).asString)
                }
            }
            .onDelete { offsets in
                for index in offsets.sorted(by: >) { value.remove(at: index) }
            }

            Section {
                Button {
                    if let template = items.first, let obj = template.object {
                        value.append(.object(obj.mapValues { existing in
                            switch existing {
                            case .string: return .string("")
                            case .int: return .int(0)
                            case .double: return .double(0)
                            case .bool: return .bool(false)
                            default: return existing
                            }
                        }))
                    } else {
                        value.append(.string(""))
                    }
                } label: {
                    Label("新增一项", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle(title)
        .toolbar { EditButton() }
    }
}

/// 「读取配置 → 编辑 → 保存」的标准页面。多数设置类接口都是这个模式。
public struct JSONConfigScreen: View {
    let title: String
    var note: String?
    let load: () async throws -> JSONValue
    let save: (JSONValue) async throws -> JSONValue
    /// 服务端返回的配置常被包在某个键里（如 `{"config": {...}}`）。
    var unwrapKeys: [String]

    @State private var draft: JSONValue = .null
    @State private var phase: Phase = .loading
    @State private var revealSecrets = false
    @StateObject private var runner = ActionRunner()
    @EnvironmentObject private var session: AppSession

    private enum Phase: Equatable {
        case loading, ready, failed(String)
    }

    public init(title: String,
                note: String? = nil,
                unwrapKeys: [String] = ["config", "data", "settings"],
                load: @escaping () async throws -> JSONValue,
                save: @escaping (JSONValue) async throws -> JSONValue) {
        self.title = title
        self.note = note
        self.unwrapKeys = unwrapKeys
        self.load = load
        self.save = save
    }

    public var body: some View {
        Form {
            switch phase {
            case .loading:
                LoadingRow()
            case .failed(let message):
                FailureRow(message: message) { Task { await reload() } }
            case .ready:
                if let note {
                    Section { Text(note).font(.footnote).foregroundStyle(.secondary) }
                }
                Section {
                    JSONObjectEditor(value: $draft, secretsRevealed: revealSecrets)
                } header: {
                    HStack {
                        Text("配置项")
                        Spacer()
                        Button(revealSecrets ? "隐藏密文" : "显示密文") { revealSecrets.toggle() }
                            .font(.caption)
                            .textCase(nil)
                    }
                }
                Section {
                    Button {
                        runner.run("已保存") { try await save(draft) }
                    } label: {
                        Label("保存配置", systemImage: "square.and.arrow.down")
                    }
                }
            }
        }
        .navigationTitle(title)
        .actionFeedback(runner)
        .task { if phase == .loading { await reload() } }
    }

    private func reload() async {
        do {
            var fetched = try await load()
            for key in unwrapKeys where fetched[key].object != nil {
                fetched = fetched[key]
                break
            }
            draft = fetched
            phase = .ready
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            phase = .failed(error.errorDescription ?? "加载失败")
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
