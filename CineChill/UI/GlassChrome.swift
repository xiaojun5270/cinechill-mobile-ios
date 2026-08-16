import SwiftUI
import UIKit

/// 导航栏 / 标签栏的「液态玻璃」外观。
///
/// 说明一件重要的事：真正的 Liquid Glass 是 iOS 26 引入的系统级材质，App 只要用 iOS 26 SDK
/// 重新编译，系统标准栏就会自动变成液态玻璃，不需要叠加自定义栏。本工程的最低系统是 iOS 17，
/// 所以这里做两件事：
///
/// 1. 用 iOS 26 SDK（Xcode 26 及以上）编译并跑在 iOS 26 上时，**什么都不做**，让系统自己画，
///    避免自定义 appearance 覆盖掉系统的真玻璃；
/// 2. 其余情况（iOS 17 / 18，或用旧 SDK 编译）在同一个系统栏上使用超薄材质做近似：
///    栏体透光、内容从栏下滑过，观感与液态玻璃一致，只是少了折射与高光动画。
public enum ChromeStyle: String, CaseIterable, Identifiable {
    /// 超薄材质，最通透。
    case liquidGlass
    /// 稍厚的材质，海报、深色内容下按钮更清楚。
    case frosted
    /// 系统默认（不透光的 chrome 材质 + 分隔线）。
    case system

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .liquidGlass: return "液态玻璃"
        case .frosted: return "磨砂玻璃"
        case .system: return "系统默认"
        }
    }

    public var detail: String {
        switch self {
        case .liquidGlass: return "超薄材质，去掉分隔线，内容直接从栏下透出"
        case .frosted: return "材质更厚一点，浅色文字在海报上更易读"
        case .system: return "iOS 原生的不透光导航栏"
        }
    }

    var blur: UIBlurEffect.Style? {
        switch self {
        case .liquidGlass: return .systemUltraThinMaterial
        case .frosted: return .systemThinMaterial
        case .system: return nil
        }
    }
}

/// 放在文件作用域，`@AppStorage` 的默认值表达式在非隔离上下文里求值，不宜引用 `@MainActor` 类型的成员。
let chromeStyleKey = "appearance.chromeStyle"

@MainActor
public enum GlassChrome {

    public nonisolated static var styleKey: String { chromeStyleKey }

    /// 用 Xcode 26 及以上（Swift 6.2+）编译时为 true——此时 SDK 自带 Liquid Glass。
    public nonisolated static var buildsWithSystemGlass: Bool {
        #if compiler(>=6.2)
        return true
        #else
        return false
        #endif
    }

    /// 当前系统是否已经是自带液态玻璃的版本。
    public nonisolated static var runsOnGlassSystem: Bool {
        ProcessInfo.processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0))
    }

    /// 系统会自己画液态玻璃，App 不该再插手。
    public nonisolated static var systemDrawsGlass: Bool {
        buildsWithSystemGlass && runsOnGlassSystem
    }

    public static var style: ChromeStyle {
        get { ChromeStyle(rawValue: UserDefaults.standard.string(forKey: styleKey) ?? "") ?? .liquidGlass }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: styleKey)
            install()
            refreshVisibleBars()
        }
    }

    /// 启动时调用一次。
    public static func install() {
        guard !systemDrawsGlass else { return }
        apply(style)
    }

    private static func apply(_ style: ChromeStyle) {
        let navigation = UINavigationBar.appearance()
        let tab = UITabBar.appearance()
        let toolbar = UIToolbar.appearance()

        guard let blur = style.blur else {
            // 恢复系统默认：把代理清空即可
            let nav = UINavigationBarAppearance()
            nav.configureWithDefaultBackground()
            navigation.standardAppearance = nav
            navigation.compactAppearance = nav
            navigation.scrollEdgeAppearance = nil
            navigation.compactScrollEdgeAppearance = nil

            let bar = UITabBarAppearance()
            bar.configureWithDefaultBackground()
            tab.standardAppearance = bar
            tab.scrollEdgeAppearance = bar

            let tools = UIToolbarAppearance()
            tools.configureWithDefaultBackground()
            toolbar.standardAppearance = tools
            toolbar.compactAppearance = tools
            toolbar.scrollEdgeAppearance = tools
            return
        }

        let effect = UIBlurEffect(style: blur)

        let glass = UINavigationBarAppearance()
        glass.configureWithTransparentBackground()
        glass.backgroundEffect = effect
        glass.backgroundColor = .clear
        // 玻璃靠材质本身分层，1px 分隔线会破坏通透感
        glass.shadowColor = style == .liquidGlass ? .clear
            : UIColor.separator.withAlphaComponent(0.35)

        // 滚到顶部时保持透明，内容与栏融为一体；一旦滚动就浮出玻璃——这正是液态玻璃的节奏
        let atEdge = UINavigationBarAppearance()
        atEdge.configureWithTransparentBackground()
        atEdge.shadowColor = .clear

        navigation.standardAppearance = glass
        navigation.compactAppearance = glass
        navigation.scrollEdgeAppearance = atEdge
        navigation.compactScrollEdgeAppearance = atEdge

        let tabGlass = UITabBarAppearance()
        tabGlass.configureWithTransparentBackground()
        tabGlass.backgroundEffect = effect
        tabGlass.backgroundColor = .clear
        tabGlass.shadowColor = style == .liquidGlass ? .clear
            : UIColor.separator.withAlphaComponent(0.35)
        tab.standardAppearance = tabGlass
        tab.scrollEdgeAppearance = tabGlass

        let toolGlass = UIToolbarAppearance()
        toolGlass.configureWithTransparentBackground()
        toolGlass.backgroundEffect = effect
        toolGlass.backgroundColor = .clear
        toolGlass.shadowColor = .clear
        toolbar.standardAppearance = toolGlass
        toolbar.compactAppearance = toolGlass
        toolbar.scrollEdgeAppearance = toolGlass
    }

    /// appearance 代理只影响之后创建的栏，切换样式时手动刷一遍已经在屏幕上的。
    public static func refreshVisibleBars() {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                restyle(window)
                window.rootViewController?.view.setNeedsLayout()
            }
        }
    }

    private static func restyle(_ view: UIView) {
        if let bar = view as? UINavigationBar {
            let proxy = UINavigationBar.appearance()
            bar.standardAppearance = proxy.standardAppearance
            bar.compactAppearance = proxy.compactAppearance
            bar.scrollEdgeAppearance = proxy.scrollEdgeAppearance
            bar.compactScrollEdgeAppearance = proxy.compactScrollEdgeAppearance
            bar.setNeedsLayout()
        }
        if let bar = view as? UITabBar {
            let proxy = UITabBar.appearance()
            bar.standardAppearance = proxy.standardAppearance
            bar.scrollEdgeAppearance = proxy.scrollEdgeAppearance
            bar.setNeedsLayout()
        }
        if let bar = view as? UIToolbar {
            let proxy = UIToolbar.appearance()
            bar.standardAppearance = proxy.standardAppearance
            bar.compactAppearance = proxy.compactAppearance
            bar.scrollEdgeAppearance = proxy.scrollEdgeAppearance
            bar.setNeedsLayout()
        }
        for child in view.subviews { restyle(child) }
    }
}

// MARK: - SwiftUI 侧的补充

/// 在 SwiftUI 层再声明一次栏体材质：某些页面（带 `.searchable`、自定义 toolbar）
/// 用 SwiftUI 的 `toolbarBackground` 表现更稳定。
struct GlassBarModifier: ViewModifier {
    @AppStorage(chromeStyleKey) private var raw = ChromeStyle.liquidGlass.rawValue

    private var style: ChromeStyle { ChromeStyle(rawValue: raw) ?? .liquidGlass }

    func body(content: Content) -> some View {
        if GlassChrome.systemDrawsGlass {
            content
        } else {
            switch style {
            case .liquidGlass:
                content.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            case .frosted:
                content.toolbarBackground(.thinMaterial, for: .navigationBar)
            case .system:
                content
            }
        }
    }
}

struct GlassTabBarModifier: ViewModifier {
    @AppStorage(chromeStyleKey) private var raw = ChromeStyle.liquidGlass.rawValue

    private var style: ChromeStyle { ChromeStyle(rawValue: raw) ?? .liquidGlass }

    func body(content: Content) -> some View {
        if GlassChrome.systemDrawsGlass {
            content
        } else {
            switch style {
            case .liquidGlass:
                content.toolbarBackground(.ultraThinMaterial, for: .tabBar)
            case .frosted:
                content.toolbarBackground(.thinMaterial, for: .tabBar)
            case .system:
                content
            }
        }
    }
}

extension View {
    /// 给当前页面的导航栏套上玻璃材质。
    func glassNavigationBar() -> some View { modifier(GlassBarModifier()) }
    /// 给标签栏套上玻璃材质（在 TabView 上调用）。
    func glassTabBar() -> some View { modifier(GlassTabBarModifier()) }
}

/// 浮在内容上的玻璃胶囊，用于自定义的悬浮按钮。
struct GlassCapsule<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.08)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing),
                        lineWidth: 0.7)
            }
            .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
    }
}

// MARK: - 设置页

/// 外观设置：导航栏材质。
struct AppearanceView: View {
    @AppStorage(chromeStyleKey) private var raw = ChromeStyle.liquidGlass.rawValue

    private var style: ChromeStyle { ChromeStyle(rawValue: raw) ?? .liquidGlass }

    var body: some View {
        Form {
            Section {
                ForEach(ChromeStyle.allCases) { option in
                    Button {
                        GlassChrome.style = option
                        raw = option.rawValue
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: raw == option.rawValue
                                  ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(raw == option.rawValue ? Color.accentColor : .secondary)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.title).foregroundStyle(.primary)
                                Text(option.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("导航栏与标签栏")
            } footer: {
                Text("切换后会立即刷新当前界面。少数已经缓存的页面可能要退出重进才会跟上。")
            }

            Section {
                GlassPreviewStrip(style: style)
            } header: {
                Text("预览")
            }

            Section {
                KeyValueRow("当前系统", systemVersionText)
                KeyValueRow("编译 SDK", GlassChrome.buildsWithSystemGlass ? "iOS 26 或更新" : "iOS 18 或更旧")
                KeyValueRow("玻璃来源", GlassChrome.systemDrawsGlass ? "系统原生" : "App 近似")
            } header: {
                Text("状态")
            } footer: {
                Text("真正的 Liquid Glass 是 iOS 26 的系统材质：用 iOS 26 SDK 重新编译后，系统栏会自动变成液态玻璃，带折射与高光。在更早的系统上，这里用超薄材质做观感一致的近似。")
            }
        }
        .navigationTitle("外观")
        .glassNavigationBar()
    }

    private var systemVersionText: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "iOS \(v.majorVersion).\(v.minorVersion)"
    }
}

/// 把材质叠在一张渐变「海报」上，直观看出通透程度。
struct GlassPreviewStrip: View {
    let style: ChromeStyle

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [.indigo, .purple, .orange],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            HStack {
                Image(systemName: "chevron.left")
                Spacer()
                Text("导航栏")
                    .font(.headline)
                Spacer()
                Image(systemName: "ellipsis.circle")
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(material)
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var material: some View {
        switch style {
        case .liquidGlass: Rectangle().fill(.ultraThinMaterial)
        case .frosted: Rectangle().fill(.thinMaterial)
        case .system: Rectangle().fill(.bar)
        }
    }
}
