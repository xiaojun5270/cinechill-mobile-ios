import SwiftUI

/// 媒体库标签页：Emby 相关模块与整理/统计入口。
struct LibraryView: View {
    var body: some View {
        List {
            Section("Emby") {
                ModuleRow(title: "Emby 总览",
                          subtitle: "媒体库数量、在线状态、封面",
                          systemImage: "square.stack.3d.up.fill",
                          tint: .blue) { EmbyOverviewView() }
                ModuleRow(title: "Emby 用户",
                          subtitle: "新增、禁用、改密、绑定",
                          systemImage: "person.2.badge.gearshape",
                          tint: .indigo) { EmbyUsersView() }
                ModuleRow(title: "Emby 任务中心",
                          subtitle: "计划任务运行与触发器",
                          systemImage: "clock.badge.checkmark",
                          tint: .teal) { EmbyTasksView() }
                ModuleRow(title: "Emby 搜索",
                          subtitle: "直接检索媒体服务器条目",
                          systemImage: "text.magnifyingglass",
                          tint: .cyan) { EmbySearchView() }
            }

            Section("整理与入库") {
                ModuleRow(title: "媒体整理",
                          subtitle: "整理配置、识别测试、手动整理",
                          systemImage: "folder.badge.gearshape",
                          tint: .orange) { MediaOrganizeView() }
                ModuleRow(title: "整理记录",
                          subtitle: "历史记录、重做、AI 重做",
                          systemImage: "clock.arrow.circlepath",
                          tint: .brown) { OrganizeHistoryView() }
                ModuleRow(title: "二级分类规则",
                          subtitle: "分类规则与默认规则对比",
                          systemImage: "square.grid.3x3",
                          tint: .purple) { CategoryRulesView() }
                ModuleRow(title: "转存历史",
                          subtitle: "手动转存与历史清理",
                          systemImage: "arrow.left.arrow.right.circle",
                          tint: .pink) { TransferHistoryView() }
            }

            Section("统计") {
                ModuleRow(title: "缺集统计",
                          subtitle: "剧集缺失情况与手动标记",
                          systemImage: "chart.bar.doc.horizontal",
                          tint: .red) { MissingEpisodesView() }
                ModuleRow(title: "整理概览",
                          subtitle: "按天统计入库数量",
                          systemImage: "chart.line.uptrend.xyaxis",
                          tint: .green) { OrganizeSummaryView() }
            }
        }
        .navigationTitle("媒体库")
    }
}
