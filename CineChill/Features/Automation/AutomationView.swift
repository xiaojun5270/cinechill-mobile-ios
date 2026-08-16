import SwiftUI

/// 自动化标签页：任务、订阅、网盘、转发、通知触发等模块索引。
struct AutomationView: View {
    var body: some View {
        List {
            Section("媒体整理") {
                ModuleRow(title: "一条龙菜单",
                          subtitle: "整理策略、监听、洗版与手动任务",
                          systemImage: "folder.badge.gearshape",
                          tint: .blue) { MediaOrganizeView() }
                ModuleRow(title: "整理记录",
                          subtitle: "历史记录、重做与 AI 重做",
                          systemImage: "clock.arrow.circlepath",
                          tint: .brown) { OrganizeHistoryView() }
                ModuleRow(title: "重命名模板",
                          subtitle: "电影、剧集目录与文件名模板",
                          systemImage: "textformat",
                          tint: .teal) { RenameTemplateView() }
                ModuleRow(title: "二级分类",
                          subtitle: "电影、剧集分类规则与 Emby 同步",
                          systemImage: "square.grid.3x3",
                          tint: .purple) { CategoryRulesView() }
            }

            Section("任务与运维") {
                ModuleRow(title: "Emby 任务中心",
                          subtitle: "计划任务运行与触发器",
                          systemImage: "clock.badge.checkmark",
                          tint: .teal) { EmbyTasksView() }
                ModuleRow(title: "Docker 管理",
                          subtitle: "容器、镜像、更新与仓库认证",
                          systemImage: "shippingbox",
                          tint: .blue) { DockerView() }
                ModuleRow(title: "115秒传",
                          subtitle: "上传任务、云端秒传与并发设置",
                          systemImage: "icloud.and.arrow.up",
                          tint: .cyan) { Upload115View() }
                ModuleRow(title: "真实库",
                          subtitle: "RSS 任务、榜单链接与硬链接入库",
                          systemImage: "dot.radiowaves.up.forward",
                          tint: .orange) { RSSView() }
                ModuleRow(title: "工具箱",
                          subtitle: "115、转存、通知与集成工具",
                          systemImage: "wrench.and.screwdriver",
                          tint: .indigo) { ToolboxView() }
            }

            Section("同步服务") {
                ModuleRow(title: "STRM 同步",
                          subtitle: "配置、同步进度、元数据回填",
                          systemImage: "link.circle",
                          tint: .mint) { StrmView() }
            }
        }
        .navigationTitle("自动化")
    }
}
