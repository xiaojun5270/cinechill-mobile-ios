import SwiftUI

/// 五个一级区域。iPhone 上是标签页，iPad 上是侧边栏。
public enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case discover
    case library
    case automation
    case settings

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .dashboard: return "仪表盘"
        case .discover: return "发现"
        case .library: return "媒体库"
        case .automation: return "自动化"
        case .settings: return "设置"
        }
    }

    public var systemImage: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.33percent"
        case .discover: return "sparkles.tv"
        case .library: return "film.stack"
        case .automation: return "bolt.badge.clock"
        case .settings: return "gearshape"
        }
    }
}

/// 一个可直接跳转的功能页。`id` 用视图类型名，稳定且不会重名，收藏与最近访问都以它为键。
public struct ModuleEntry: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let group: String
    public let tab: AppTab
    public let systemImage: String
    public let tint: Color
    /// 额外的命中词：英文名、接口路径、同义说法，搜索时一起匹配。
    public let keywords: String
    public let destination: () -> AnyView

    public static func == (lhs: ModuleEntry, rhs: ModuleEntry) -> Bool { lhs.id == rhs.id }

    func matches(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return true }
        for word in needle.split(separator: " ") {
            let part = String(word)
            let hit = title.lowercased().contains(part)
                || group.lowercased().contains(part)
                || keywords.lowercased().contains(part)
                || id.lowercased().contains(part)
            if !hit { return false }
        }
        return true
    }
}

/// 收藏与最近访问：只存 id，页面本身仍由 `ModuleIndex` 提供。
@MainActor
public final class ModuleFavorites: ObservableObject {
    private enum Key {
        static let favorites = "modules.favorites"
        static let recents = "modules.recents"
    }

    private static let recentLimit = 8

    @Published public private(set) var favoriteIDs: [String]
    @Published public private(set) var recentIDs: [String]

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        favoriteIDs = defaults.stringArray(forKey: Key.favorites) ?? []
        recentIDs = defaults.stringArray(forKey: Key.recents) ?? []
    }

    public func isFavorite(_ id: String) -> Bool { favoriteIDs.contains(id) }

    public func toggle(_ id: String) {
        if let index = favoriteIDs.firstIndex(of: id) {
            favoriteIDs.remove(at: index)
        } else {
            favoriteIDs.append(id)
        }
        defaults.set(favoriteIDs, forKey: Key.favorites)
    }

    public func noteVisit(_ id: String) {
        recentIDs.removeAll { $0 == id }
        recentIDs.insert(id, at: 0)
        if recentIDs.count > Self.recentLimit {
            recentIDs = Array(recentIDs.prefix(Self.recentLimit))
        }
        defaults.set(recentIDs, forKey: Key.recents)
    }

    public func clearRecents() {
        recentIDs = []
        defaults.set(recentIDs, forKey: Key.recents)
    }

    /// 收藏的页面，顺序按用户添加的顺序；已经不存在的 id 自动忽略。
    public var favorites: [ModuleEntry] {
        favoriteIDs.compactMap { ModuleIndex.entry(id: $0) }
    }

    /// 最近访问，排除已收藏的，避免首页出现两遍。
    public var recents: [ModuleEntry] {
        recentIDs.filter { !favoriteIDs.contains($0) }.compactMap { ModuleIndex.entry(id: $0) }
    }
}

/// 全部功能页的索引。凡是「不需要外部参数就能打开」的页面都登记在此，供搜索与收藏使用。
public enum ModuleIndex {

    public static let all: [ModuleEntry] =
        systemItems + discoverItems + libraryItems + automationItems + settingsItems

    private static let lookup: [String: ModuleEntry] = {
        var map: [String: ModuleEntry] = [:]
        for item in all { map[item.id] = item }
        return map
    }()

    public static func entry(id: String) -> ModuleEntry? { lookup[id] }

    public static func items(for tab: AppTab) -> [ModuleEntry] { all.filter { $0.tab == tab } }

    // MARK: - 仪表盘 / 系统

    private static let systemItems: [ModuleEntry] = [
        ModuleEntry(id: "TaskCenterView", title: "任务中心", group: "系统", tab: .dashboard,
                    systemImage: "list.bullet.rectangle.portrait", tint: .blue,
                    keywords: "task 任务 进度 计划任务 定时 停止 /api/tasks") { AnyView(TaskCenterView()) },
        ModuleEntry(id: "SystemLogsView", title: "系统日志", group: "系统", tab: .dashboard,
                    systemImage: "doc.plaintext", tint: .gray,
                    keywords: "log 日志 报错 排查 /api/system_logs") { AnyView(SystemLogsView()) },
        ModuleEntry(id: "SystemHealthView", title: "系统健康", group: "系统", tab: .dashboard,
                    systemImage: "heart.text.square", tint: .red,
                    keywords: "health cpu 内存 磁盘 体检 /api/system_health") { AnyView(SystemHealthView()) },
        ModuleEntry(id: "NetworkCheckView", title: "网络连通性", group: "系统", tab: .dashboard,
                    systemImage: "network", tint: .teal,
                    keywords: "network ping 连通 外网 tmdb 检测") { AnyView(NetworkCheckView()) },
    ]

    // MARK: - 发现

    private static let discoverItems: [ModuleEntry] = [
        ModuleEntry(id: "MediaSearchView", title: "搜索影视", group: "发现", tab: .discover,
                    systemImage: "magnifyingglass", tint: .blue,
                    keywords: "search 搜索 tmdb 影片 剧集 /api/discover/search") { AnyView(MediaSearchView()) },
        ModuleEntry(id: "DiscoverBrowseView", title: "浏览发现", group: "发现", tab: .discover,
                    systemImage: "square.grid.2x2", tint: .indigo,
                    keywords: "browse 数据源 榜单 douban tmdb bangumi 实时事件") { AnyView(DiscoverBrowseView()) },
        ModuleEntry(id: "DoubanResolveView", title: "豆瓣 → TMDb 匹配", group: "发现", tab: .discover,
                    systemImage: "arrow.triangle.swap", tint: .green,
                    keywords: "douban 豆瓣 匹配 resolve 转换") { AnyView(DoubanResolveView()) },
        ModuleEntry(id: "TmdbArtworkBatchView", title: "批量海报", group: "发现", tab: .discover,
                    systemImage: "photo.stack", tint: .orange,
                    keywords: "artwork 海报 批量 poster /api/discover/tmdb_artwork") { AnyView(TmdbArtworkBatchView()) },
    ]

    // MARK: - 媒体库

    private static let libraryItems: [ModuleEntry] = [
        ModuleEntry(id: "DiscoverRecommendationsView", title: "发现推荐", group: "媒体服务", tab: .library,
                    systemImage: "safari", tint: .blue,
                    keywords: "discover recommend 发现 推荐 今日精选 热门 榜单") { AnyView(DiscoverView()) },
        ModuleEntry(id: "EmbyOverviewView", title: "Emby 总览", group: "Emby", tab: .library,
                    systemImage: "square.stack.3d.up.fill", tint: .blue,
                    keywords: "emby 媒体库 封面 在线 libraries") { AnyView(EmbyOverviewView()) },
        ModuleEntry(id: "EmbyUsersView", title: "Emby 用户", group: "Emby", tab: .library,
                    systemImage: "person.2.badge.gearshape", tint: .indigo,
                    keywords: "user 用户 改密 禁用 绑定 /api/emby/users") { AnyView(EmbyUsersView()) },
        ModuleEntry(id: "EmbyTasksView", title: "Emby 任务中心", group: "任务与运维", tab: .automation,
                    systemImage: "clock.badge.checkmark", tint: .teal,
                    keywords: "emby task 计划任务 触发器 scheduled") { AnyView(EmbyTasksView()) },
        ModuleEntry(id: "EmbySearchView", title: "Emby 搜索", group: "Emby", tab: .library,
                    systemImage: "text.magnifyingglass", tint: .cyan,
                    keywords: "emby search 检索 条目") { AnyView(EmbySearchView()) },
        ModuleEntry(id: "EmbyItemsDeleteView", title: "删除 Emby 条目", group: "Emby", tab: .library,
                    systemImage: "trash", tint: .red,
                    keywords: "delete 删除 emby 条目 清理") { AnyView(EmbyItemsDeleteView()) },
        ModuleEntry(id: "OrganizeConfigView", title: "整理配置", group: "媒体整理", tab: .automation,
                    systemImage: "slider.horizontal.3", tint: .gray,
                    keywords: "organize config 命名模板 目录 规则") { AnyView(OrganizeConfigView()) },
        ModuleEntry(id: "SubClassifyConfigView", title: "二级分类配置", group: "媒体整理", tab: .automation,
                    systemImage: "square.grid.3x3", tint: .purple,
                    keywords: "sub classify 二级分类 动画 纪录片") { AnyView(SubClassifyConfigView()) },
        ModuleEntry(id: "IdentifyTestView", title: "识别测试", group: "媒体整理", tab: .automation,
                    systemImage: "wand.and.stars", tint: .pink,
                    keywords: "identify 识别 测试 文件名 解析") { AnyView(IdentifyTestView()) },
        ModuleEntry(id: "ManualOrganizeView", title: "手动整理", group: "媒体整理", tab: .automation,
                    systemImage: "hand.point.up.left", tint: .brown,
                    keywords: "manual 手动 指定 整理 单个") { AnyView(ManualOrganizeView()) },
        ModuleEntry(id: "OrganizeHistoryView", title: "整理记录", group: "媒体整理", tab: .automation,
                    systemImage: "clock.arrow.circlepath", tint: .brown,
                    keywords: "history 历史 重做 redo ai /api/organize_history") { AnyView(OrganizeHistoryView()) },
        ModuleEntry(id: "OrganizeSummaryView", title: "整理概览", group: "统计", tab: .library,
                    systemImage: "chart.line.uptrend.xyaxis", tint: .green,
                    keywords: "summary 统计 按天 入库量") { AnyView(OrganizeSummaryView()) },
        ModuleEntry(id: "CategoryRulesView", title: "二级分类", group: "媒体整理", tab: .automation,
                    systemImage: "square.grid.3x3.square", tint: .purple,
                    keywords: "category rules 分类规则 默认规则") { AnyView(CategoryRulesView()) },
        ModuleEntry(id: "TransferHistoryView", title: "资源转存", group: "工具箱", tab: .automation,
                    systemImage: "arrow.left.arrow.right.circle", tint: .pink,
                    keywords: "transfer 转存 分享链接 history") { AnyView(TransferHistoryView()) },
        ModuleEntry(id: "MissingEpisodesView", title: "缺集统计", group: "媒体服务", tab: .library,
                    systemImage: "chart.bar.doc.horizontal", tint: .red,
                    keywords: "missing 缺集 缺失 剧集 补全") { AnyView(MissingEpisodesView()) },
    ]

    // MARK: - 自动化

    private static let automationItems: [ModuleEntry] = [
        ModuleEntry(id: "MediaOrganizeView", title: "一条龙菜单", group: "媒体整理", tab: .automation,
                    systemImage: "folder.badge.gearshape", tint: .blue,
                    keywords: "one stop 一条龙 organize 整理 监听 洗版 手动任务 /api/media_organize") {
            AnyView(MediaOrganizeView())
        },
        ModuleEntry(id: "RenameTemplateView", title: "重命名模板", group: "媒体整理", tab: .automation,
                    systemImage: "textformat", tint: .teal,
                    keywords: "rename template 重命名 模板 电影 剧集 文件名") { AnyView(RenameTemplateView()) },
        ModuleEntry(id: "RSSView", title: "真实库", group: "任务与运维", tab: .automation,
                    systemImage: "dot.radiowaves.up.forward", tint: .orange,
                    keywords: "rss 真实库 订阅 feed 抓取 硬链接 /api/rss") { AnyView(RSSView()) },
        ModuleEntry(id: "RSSTasksView", title: "RSS 任务", group: "RSS", tab: .automation,
                    systemImage: "list.bullet.below.rectangle", tint: .orange,
                    keywords: "rss task 任务 规则 开关") { AnyView(RSSTasksView()) },
        ModuleEntry(id: "RSSConfigView", title: "RSS 全局配置", group: "RSS", tab: .automation,
                    systemImage: "slider.horizontal.3", tint: .gray,
                    keywords: "rss config 间隔 并发 全局") { AnyView(RSSConfigView()) },
        ModuleEntry(id: "RSSPresetsView", title: "链接生成器", group: "RSS", tab: .automation,
                    systemImage: "link.badge.plus", tint: .blue,
                    keywords: "preset 生成 链接 mteam 站点 参数") { AnyView(RSSPresetsView()) },
        ModuleEntry(id: "RSSPreviewView", title: "订阅预览", group: "RSS", tab: .automation,
                    systemImage: "eye", tint: .teal,
                    keywords: "preview 预览 试抓 条目") { AnyView(RSSPreviewView()) },
        ModuleEntry(id: "RSSBuiltinFeedsView", title: "内置榜单直连", group: "RSS", tab: .automation,
                    systemImage: "star.square.on.square", tint: .yellow,
                    keywords: "builtin 内置 榜单 豆瓣 top250") { AnyView(RSSBuiltinFeedsView()) },
        ModuleEntry(id: "SubscriptionsView", title: "订阅系统", group: "媒体服务", tab: .library,
                    systemImage: "bell.badge", tint: .pink,
                    keywords: "subscribe 订阅 追剧 电影 /api/subscriptions") { AnyView(SubscriptionsView()) },
        ModuleEntry(id: "SubscriptionSourcesView", title: "订阅源", group: "媒体服务", tab: .library,
                    systemImage: "antenna.radiowaves.left.and.right", tint: .pink,
                    keywords: "source 订阅源 站点 索引器") { AnyView(SubscriptionSourcesView()) },
        ModuleEntry(id: "SubscriptionEventsView", title: "订阅事件", group: "媒体服务", tab: .library,
                    systemImage: "waveform.path.ecg", tint: .purple,
                    keywords: "event 事件 实时 sse 推送") { AnyView(SubscriptionEventsView()) },
        ModuleEntry(id: "SubscriptionActivityView", title: "订阅动态", group: "媒体服务", tab: .library,
                    systemImage: "clock.badge", tint: .purple,
                    keywords: "activity 动态 记录 命中") { AnyView(SubscriptionActivityView()) },
        ModuleEntry(id: "MoviePilotView", title: "MoviePilot", group: "订阅", tab: .automation,
                    systemImage: "airplane.circle", tint: .indigo,
                    keywords: "moviepilot mp 对接 下载器") { AnyView(MoviePilotView()) },
        ModuleEntry(id: "MoviePilotConfigView", title: "MoviePilot 配置", group: "订阅", tab: .automation,
                    systemImage: "gearshape.2", tint: .gray,
                    keywords: "moviepilot config 地址 令牌") { AnyView(MoviePilotConfigView()) },
        ModuleEntry(id: "MoviePilotSitesView", title: "站点管理", group: "媒体服务", tab: .library,
                    systemImage: "network", tint: .indigo,
                    keywords: "moviepilot site 站点 健康 监控 洗版 自动下载") { AnyView(MoviePilotSitesView()) },
        ModuleEntry(id: "Cleanup115View", title: "115 清理", group: "115 网盘", tab: .automation,
                    systemImage: "trash.circle", tint: .red,
                    keywords: "115 cleanup 清理 空目录 回收站") { AnyView(Cleanup115View()) },
        ModuleEntry(id: "Upload115View", title: "115秒传", group: "任务与运维", tab: .automation,
                    systemImage: "arrow.up.doc", tint: .blue,
                    keywords: "115 upload 上传 本地 目录") { AnyView(Upload115View()) },
        ModuleEntry(id: "UploadThreadSettingsView", title: "并发设置", group: "115 网盘", tab: .automation,
                    systemImage: "speedometer", tint: .gray,
                    keywords: "thread 并发 线程 限速 上传") { AnyView(UploadThreadSettingsView()) },
        ModuleEntry(id: "Cloud115RapidView", title: "网盘资源秒传", group: "工具箱", tab: .automation,
                    systemImage: "bolt.horizontal.circle", tint: .yellow,
                    keywords: "rapid 秒传 sha1 复制 云端") { AnyView(Cloud115RapidView()) },
        ModuleEntry(id: "StrmView", title: "STRM 同步", group: "STRM", tab: .automation,
                    systemImage: "doc.badge.arrow.up", tint: .green,
                    keywords: "strm 生成 同步 直链 /api/strm") { AnyView(StrmView()) },
        ModuleEntry(id: "StrmConfigView", title: "STRM 配置", group: "STRM", tab: .automation,
                    systemImage: "slider.horizontal.below.rectangle", tint: .gray,
                    keywords: "strm config 前缀 路径 映射") { AnyView(StrmConfigView()) },
        ModuleEntry(id: "ForwardView", title: "资源转发", group: "转发与签到", tab: .automation,
                    systemImage: "arrowshape.turn.up.forward", tint: .cyan,
                    keywords: "forward 转发 分享 群组 /api/forward") { AnyView(ForwardView()) },
        ModuleEntry(id: "ForwardSearchView", title: "资源搜索", group: "转发与签到", tab: .automation,
                    systemImage: "sparkle.magnifyingglass", tint: .cyan,
                    keywords: "forward search 搜索 资源 转存") { AnyView(ForwardSearchView()) },
        ModuleEntry(id: "WebhookView", title: "Webhook", group: "转发与签到", tab: .automation,
                    systemImage: "point.3.connected.trianglepath.dotted", tint: .brown,
                    keywords: "webhook 回调 emby 播放 通知") { AnyView(WebhookView()) },
        ModuleEntry(id: "FnosSignView", title: "飞牛签到", group: "转发与签到", tab: .automation,
                    systemImage: "checkmark.seal", tint: .green,
                    keywords: "fnos 飞牛 签到 每日") { AnyView(FnosSignView()) },
        ModuleEntry(id: "DockerView", title: "Docker 管理", group: "任务与运维", tab: .automation,
                    systemImage: "shippingbox", tint: .blue,
                    keywords: "docker 容器 重启 日志 /api/docker") { AnyView(DockerView()) },
        ModuleEntry(id: "DockerImagesView", title: "镜像管理", group: "Docker", tab: .automation,
                    systemImage: "square.stack.3d.down.right", tint: .blue,
                    keywords: "image 镜像 拉取 清理 pull") { AnyView(DockerImagesView()) },
        ModuleEntry(id: "DockerRegistryView", title: "仓库凭据", group: "Docker", tab: .automation,
                    systemImage: "key.horizontal", tint: .gray,
                    keywords: "registry 仓库 凭据 登录 私有") { AnyView(DockerRegistryView()) },
        ModuleEntry(id: "ToolboxView", title: "工具箱", group: "任务与运维", tab: .automation,
                    systemImage: "wrench.and.screwdriver", tint: .indigo,
                    keywords: "toolbox 工具箱 115 forward webhook telegram moviepilot proxy tmdb") {
            AnyView(ToolboxView())
        },
    ]

    // MARK: - 设置

    private static let settingsItems: [ModuleEntry] = [
        ModuleEntry(id: "AccountView", title: "账户管理", group: "系统配置", tab: .settings,
                    systemImage: "person.crop.circle", tint: .blue,
                    keywords: "account 账号 密码 会话 登出") { AnyView(AccountView()) },
        ModuleEntry(id: "ServerListView", title: "服务器", group: "账号与服务器", tab: .settings,
                    systemImage: "server.rack", tint: .indigo,
                    keywords: "server 服务器 地址 切换 多站点") { AnyView(ServerListView()) },
        ModuleEntry(id: "ServerConfigView", title: "服务端参数", group: "服务端", tab: .settings,
                    systemImage: "slider.vertical.3", tint: .gray,
                    keywords: "config 配置 参数 保存 /api/config") { AnyView(ServerConfigView()) },
        ModuleEntry(id: "ServerRawConfigView", title: "服务端高级配置", group: "服务端", tab: .settings,
                    systemImage: "slider.horizontal.3", tint: .gray,
                    keywords: "raw json 原始 配置 高级") { AnyView(ServerAdvancedConfigView()) },
        ModuleEntry(id: "Config302View", title: "服务器配置", group: "系统配置", tab: .settings,
                    systemImage: "arrow.uturn.forward.circle", tint: .teal,
                    keywords: "302 重定向 网盘 cookie 直链 /api/config_302") { AnyView(Config302View()) },
        ModuleEntry(id: "Config302RawView", title: "302 高级配置", group: "302 与网盘", tab: .settings,
                    systemImage: "slider.horizontal.3", tint: .gray,
                    keywords: "302 raw json 原始 高级") { AnyView(Config302AdvancedConfigView()) },
        ModuleEntry(id: "Cookie115TestView", title: "测试 Cookie", group: "302 与网盘", tab: .settings,
                    systemImage: "checkmark.shield", tint: .green,
                    keywords: "cookie 115 测试 有效期 校验") { AnyView(Cookie115TestView()) },
        ModuleEntry(id: "StandardTopologyView", title: "标准目录结构", group: "302 与网盘", tab: .settings,
                    systemImage: "folder.badge.questionmark", tint: .orange,
                    keywords: "topology 目录 结构 标准 规范") { AnyView(StandardTopologyView()) },
        ModuleEntry(id: "NotifyView", title: "通知配置", group: "系统配置", tab: .settings,
                    systemImage: "bell.badge.waveform", tint: .red,
                    keywords: "notify 通知 推送 渠道 /api/notify") { AnyView(NotifyView()) },
        ModuleEntry(id: "TelegramNotifyView", title: "Telegram", group: "通知", tab: .settings,
                    systemImage: "paperplane", tint: .blue,
                    keywords: "telegram tg bot 机器人 token") { AnyView(TelegramNotifyView()) },
        ModuleEntry(id: "TelegramLoginView", title: "Telegram 登录", group: "通知", tab: .settings,
                    systemImage: "person.badge.key", tint: .blue,
                    keywords: "telegram login 验证码 会话 登录") { AnyView(TelegramLoginView()) },
        ModuleEntry(id: "TelegramDialogsView", title: "监听会话", group: "通知", tab: .settings,
                    systemImage: "bubble.left.and.bubble.right", tint: .blue,
                    keywords: "dialog 会话 监听 群组 频道") { AnyView(TelegramDialogsView()) },
        ModuleEntry(id: "WechatNotifyView", title: "企业微信", group: "通知", tab: .settings,
                    systemImage: "message.badge", tint: .green,
                    keywords: "wechat 微信 企业微信 corp 应用") { AnyView(WechatNotifyView()) },
        ModuleEntry(id: "NotifyTemplatesView", title: "默认模板", group: "通知", tab: .settings,
                    systemImage: "text.badge.checkmark", tint: .gray,
                    keywords: "template 模板 文案 变量") { AnyView(NotifyTemplatesView()) },
        ModuleEntry(id: "TaskNotifyView", title: "任务通知", group: "通知", tab: .settings,
                    systemImage: "app.badge", tint: .red,
                    keywords: "local notification 本地通知 完成 提醒 后台刷新 badge") { AnyView(TaskNotifyView()) },
        ModuleEntry(id: "AIAssistantView", title: "AI助手", group: "系统配置", tab: .settings,
                    systemImage: "sparkles", tint: .purple,
                    keywords: "ai 助手 对话 模型 /api/ai") { AnyView(AIAssistantView()) },
        ModuleEntry(id: "AIMemoryView", title: "记忆与人设", group: "AI 助手", tab: .settings,
                    systemImage: "brain", tint: .purple,
                    keywords: "memory 记忆 人设 persona 提示词") { AnyView(AIMemoryView()) },
        ModuleEntry(id: "AIRemindersView", title: "提醒事项", group: "AI 助手", tab: .settings,
                    systemImage: "checklist", tint: .pink,
                    keywords: "reminder 提醒 待办 定时") { AnyView(AIRemindersView()) },
        ModuleEntry(id: "AIToolPermissionsView", title: "工具权限", group: "AI 助手", tab: .settings,
                    systemImage: "hand.raised.square", tint: .orange,
                    keywords: "tool permission 权限 授权 危险操作") { AnyView(AIToolPermissionsView()) },
        ModuleEntry(id: "AIAuditView", title: "调用审计", group: "AI 助手", tab: .settings,
                    systemImage: "doc.text.magnifyingglass", tint: .gray,
                    keywords: "audit 审计 调用 记录 日志") { AnyView(AIAuditView()) },
        ModuleEntry(id: "AIContextView", title: "当前上下文", group: "AI 助手", tab: .settings,
                    systemImage: "text.alignleft", tint: .gray,
                    keywords: "context 上下文 会话 内容") { AnyView(AIContextView()) },
        ModuleEntry(id: "ResourcesView", title: "素材与模板", group: "素材与模板", tab: .settings,
                    systemImage: "square.on.square.dashed", tint: .orange,
                    keywords: "resource 素材 模板 字体 布局") { AnyView(ResourcesView()) },
        ModuleEntry(id: "FontsView", title: "字体", group: "素材与模板", tab: .settings,
                    systemImage: "textformat", tint: .orange,
                    keywords: "font 字体 上传 删除") { AnyView(FontsView()) },
        ModuleEntry(id: "LayoutsView", title: "布局", group: "素材与模板", tab: .settings,
                    systemImage: "rectangle.3.group", tint: .orange,
                    keywords: "layout 布局 排版 海报") { AnyView(LayoutsView()) },
        ModuleEntry(id: "TemplatesView", title: "模板", group: "素材与模板", tab: .settings,
                    systemImage: "doc.on.doc", tint: .orange,
                    keywords: "template 模板 套用 预设") { AnyView(TemplatesView()) },
        ModuleEntry(id: "TranslationsView", title: "译名表", group: "素材与模板", tab: .settings,
                    systemImage: "character.book.closed", tint: .teal,
                    keywords: "translation 译名 翻译 词条 类型") { AnyView(TranslationsView()) },
        ModuleEntry(id: "SuitesView", title: "套装备份", group: "素材与模板", tab: .settings,
                    systemImage: "archivebox", tint: .brown,
                    keywords: "suite 套装 备份 导入 导出") { AnyView(SuitesView()) },
        ModuleEntry(id: "LoginPostersView", title: "登录页海报", group: "素材与模板", tab: .settings,
                    systemImage: "photo.on.rectangle.angled", tint: .pink,
                    keywords: "login poster 登录页 背景 海报") { AnyView(LoginPostersView()) },
        ModuleEntry(id: "PosterApplyView", title: "预览与套用", group: "素材与模板", tab: .settings,
                    systemImage: "wand.and.rays", tint: .pink,
                    keywords: "apply 套用 预览 生成 海报") { AnyView(PosterApplyView()) },
        ModuleEntry(id: "AppearanceView", title: "明暗与导航栏外观", group: "应用", tab: .settings,
                    systemImage: "paintbrush.pointed", tint: .indigo,
                    keywords: "appearance 外观 日间 夜间 跟随系统 液态玻璃 liquid glass 导航栏 材质") { AnyView(AppearanceView()) },
        ModuleEntry(id: "AppLockView", title: "应用锁", group: "应用", tab: .settings,
                    systemImage: "faceid", tint: .green,
                    keywords: "lock 应用锁 face id touch id 密码 隐私") { AnyView(AppLockView()) },
        ModuleEntry(id: "UpgradeView", title: "版本升级", group: "应用", tab: .settings,
                    systemImage: "arrow.up.circle", tint: .blue,
                    keywords: "upgrade 升级 更新 版本 /api/upgrade") { AnyView(UpgradeView()) },
        ModuleEntry(id: "AboutView", title: "关于", group: "应用", tab: .settings,
                    systemImage: "info.circle", tint: .gray,
                    keywords: "about 关于 版本 说明") { AnyView(AboutView()) },
    ]
}
