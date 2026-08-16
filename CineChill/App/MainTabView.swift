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

    var body: some View {
        tabs
            .glassTabBar()
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
