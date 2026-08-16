import SwiftUI

/// 媒体库标签页：发现、订阅、站点与 Emby 库管理。
struct LibraryView: View {
    var body: some View {
        List {
            Section("媒体服务") {
                ModuleRow(title: "发现推荐",
                          subtitle: "今日精选、热门榜单与影视搜索",
                          systemImage: "safari",
                          tint: .blue) { DiscoverView() }
                ModuleRow(title: "缺集统计",
                          subtitle: "剧集缺失情况与手动标记",
                          systemImage: "checklist",
                          tint: .cyan) { MissingEpisodesView() }
                ModuleRow(title: "订阅系统",
                          subtitle: "订阅管理、同步进度与动态",
                          systemImage: "heart",
                          tint: .pink) { SubscriptionsView() }
                ModuleRow(title: "站点管理",
                          subtitle: "MoviePilot 站点健康与监控策略",
                          systemImage: "point.3.connected.trianglepath.dotted",
                          tint: .indigo) { MoviePilotSitesView() }
            }

            Section("Emby") {
                ModuleRow(title: "Emby 总览",
                          subtitle: "媒体库数量、在线状态、封面",
                          systemImage: "square.stack.3d.up.fill",
                          tint: .blue) { EmbyOverviewView() }
                ModuleRow(title: "Emby 用户",
                          subtitle: "新增、禁用、改密、绑定",
                          systemImage: "person.2.badge.gearshape",
                          tint: .indigo) { EmbyUsersView() }
                ModuleRow(title: "Emby 搜索",
                          subtitle: "直接检索媒体服务器条目",
                          systemImage: "text.magnifyingglass",
                          tint: .cyan) { EmbySearchView() }
            }

            Section("统计") {
                ModuleRow(title: "整理概览",
                          subtitle: "按天统计入库数量",
                          systemImage: "chart.line.uptrend.xyaxis",
                          tint: .green) { OrganizeSummaryView() }
            }
        }
        .navigationTitle("媒体库")
    }
}
