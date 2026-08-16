import SwiftUI

/// 主界面：iPhone 上是 5 个标签页，iPad（以及横屏 regular 宽度）上是侧边栏 + 详情两栏。
struct MainTabView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            SidebarLayout()
        } else {
            TabLayout()
        }
    }
}

/// 五个一级区域的根页面。
struct TabRootView: View {
    let tab: AppTab

    var body: some View {
        switch tab {
        case .dashboard: DashboardView()
        case .discover: DiscoverView()
        case .library: LibraryView()
        case .automation: AutomationView()
        case .settings: SettingsView()
        }
    }
}

// MARK: - iPhone

private struct TabLayout: View {
    @State private var selection: AppTab = .dashboard

    @ViewBuilder
    var body: some View {
        if GlassChrome.systemDrawsGlass {
            tabs
                .glassTabBar()
        } else {
            tabs
                .toolbar(.hidden, for: .tabBar)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    LiquidGlassTabBar(selection: $selection)
                        .padding(.horizontal, 12)
                        .padding(.top, 6)
                        .padding(.bottom, 4)
                }
        }
    }

    private var tabs: some View {
        TabView(selection: $selection) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    TabRootView(tab: tab)
                        .glassNavigationBar()
                }
                .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                .tag(tab)
            }
        }
    }
}

/// iOS 17/18 上的 Liquid Glass 兼容标签栏。iOS 26 + 新 SDK 会直接使用系统标签栏。
private struct LiquidGlassTabBar: View {
    @Binding var selection: AppTab
    @AppStorage(chromeStyleKey) private var rawStyle = ChromeStyle.liquidGlass.rawValue
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var selectionAnimation

    private var style: ChromeStyle {
        ChromeStyle(rawValue: rawStyle) ?? .liquidGlass
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.28, extraBounce: 0.06)) {
                        selection = tab
                    }
                } label: {
                    ZStack {
                        if selection == tab {
                            Capsule()
                                .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.24 : 0.14))
                                .overlay {
                                    Capsule()
                                        .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 0.6)
                                }
                                .matchedGeometryEffect(id: "selected-tab", in: selectionAnimation)
                        }
                        VStack(spacing: 3) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 19, weight: .medium))
                                .symbolVariant(selection == tab ? .fill : .none)
                            Text(tab.title)
                                .font(.caption2.weight(selection == tab ? .semibold : .regular))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(selection == tab ? Color.accentColor : Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(5)
        .frame(maxWidth: 560)
        .background { glassBackground }
    }

    @ViewBuilder
    private var glassBackground: some View {
        let shape = Capsule()
        switch style {
        case .liquidGlass:
            shape.fill(.ultraThinMaterial)
        case .frosted:
            shape.fill(.thinMaterial)
        case .system:
            shape.fill(.bar)
        }
        shape
            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.58), lineWidth: 0.7)
        shape
            .strokeBorder(Color.black.opacity(colorScheme == .dark ? 0.28 : 0.08), lineWidth: 0.35)
        shape
            .fill(Color.clear)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.14),
                    radius: 14, y: 6)
    }
}

// MARK: - iPad

/// 侧边栏可选的条目：五个区域、全部功能，以及收藏的具体页面。
enum SidebarItem: Hashable {
    case tab(AppTab)
    case allModules
    case module(String)
}

private struct SidebarLayout: View {
    @EnvironmentObject private var favorites: ModuleFavorites
    @State private var selection: SidebarItem? = .tab(.dashboard)
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selection) {
                Section {
                    ForEach(AppTab.allCases) { tab in
                        NavigationLink(value: SidebarItem.tab(tab)) {
                            Label(tab.title, systemImage: tab.systemImage)
                        }
                    }
                } header: {
                    Text("模块")
                }

                Section {
                    NavigationLink(value: SidebarItem.allModules) {
                        Label("全部功能", systemImage: "magnifyingglass")
                    }
                    ForEach(favorites.favorites) { entry in
                        NavigationLink(value: SidebarItem.module(entry.id)) {
                            Label(entry.title, systemImage: entry.systemImage)
                        }
                    }
                } header: {
                    Text("收藏")
                } footer: {
                    if favorites.favorites.isEmpty {
                        Text("在「全部功能」里左滑页面即可收藏到这里。")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("CineChill")
            .glassNavigationBar()
        } detail: {
            NavigationStack {
                detailContent
                    .glassNavigationBar()
            }
            // 换栏目时重建导航栈，免得上一个栏目的详情页留在右侧
            .id(selection)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection ?? .tab(.dashboard) {
        case .tab(let tab):
            TabRootView(tab: tab)
        case .allModules:
            ModuleSearchView()
        case .module(let id):
            if let entry = ModuleIndex.entry(id: id) {
                entry.destination()
            } else {
                TabRootView(tab: .dashboard)
            }
        }
    }
}

/// 统一的「模块入口」行，用于各标签页的功能索引。
struct ModuleRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = .accentColor
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(tint.gradient, in: RoundedRectangle(cornerRadius: 7))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
