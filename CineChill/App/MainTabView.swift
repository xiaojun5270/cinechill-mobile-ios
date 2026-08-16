import SwiftUI

/// 主界面：5 个标签页对应 Web 后台的五大区域。
struct MainTabView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("仪表盘", systemImage: "gauge.with.dots.needle.33percent") }

            NavigationStack { DiscoverView() }
                .tabItem { Label("发现", systemImage: "sparkles.tv") }

            NavigationStack { LibraryView() }
                .tabItem { Label("媒体库", systemImage: "film.stack") }

            NavigationStack { AutomationView() }
                .tabItem { Label("自动化", systemImage: "bolt.badge.clock") }

            NavigationStack { SettingsView() }
                .tabItem { Label("设置", systemImage: "gearshape") }
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
