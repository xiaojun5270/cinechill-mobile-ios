import SwiftUI

/// 自动化标签页：任务、订阅、网盘、转发、通知触发等模块索引。
struct AutomationView: View {
    var body: some View {
        List {
            Section("任务与日志") {
                ModuleRow(title: "任务中心",
                          subtitle: "运行进度、计划任务、停止与清理",
                          systemImage: "list.bullet.rectangle.portrait",
                          tint: .blue) { TaskCenterView() }
                ModuleRow(title: "系统日志",
                          subtitle: "按级别与关键词筛选",
                          systemImage: "doc.plaintext",
                          tint: .gray) { SystemLogsView() }
                ModuleRow(title: "系统健康",
                          subtitle: "CPU / 内存 / 磁盘、网络连通性",
                          systemImage: "heart.text.square",
                          tint: .red) { SystemHealthView() }
            }

            Section("订阅与 RSS") {
                ModuleRow(title: "RSS 订阅",
                          subtitle: "任务、链接生成器、预览与立即运行",
                          systemImage: "dot.radiowaves.up.forward",
                          tint: .orange) { RSSView() }
                ModuleRow(title: "订阅中心",
                          subtitle: "订阅源、同步、事件与动态",
                          systemImage: "bell.badge",
                          tint: .pink) { SubscriptionsView() }
                ModuleRow(title: "MoviePilot",
                          subtitle: "连接配置与订阅列表",
                          systemImage: "arrow.triangle.branch",
                          tint: .indigo) { MoviePilotView() }
            }

            Section("115 网盘") {
                ModuleRow(title: "网盘清理",
                          subtitle: "清理任务、目录浏览、立即执行",
                          systemImage: "trash.circle",
                          tint: .teal) { Cleanup115View() }
                ModuleRow(title: "网盘上传",
                          subtitle: "上传任务、秒传、线程设置",
                          systemImage: "arrow.up.circle",
                          tint: .cyan) { Upload115View() }
                ModuleRow(title: "STRM 同步",
                          subtitle: "配置、同步进度、元数据回填",
                          systemImage: "link.circle",
                          tint: .mint) { StrmView() }
            }

            Section("资源与集成") {
                ModuleRow(title: "资源搜索转发",
                          subtitle: "搜索源、预览、转存与播放",
                          systemImage: "magnifyingglass.circle",
                          tint: .purple) { ForwardView() }
                ModuleRow(title: "Webhook",
                          subtitle: "Emby Webhook 配置与队列",
                          systemImage: "arrow.left.arrow.right",
                          tint: .brown) { WebhookView() }
                ModuleRow(title: "Docker 管理",
                          subtitle: "容器、镜像、更新与仓库认证",
                          systemImage: "shippingbox",
                          tint: .blue) { DockerView() }
                ModuleRow(title: "飞牛签到",
                          subtitle: "Cookie 测试、立即签到、历史",
                          systemImage: "checkmark.seal",
                          tint: .green) { FnosSignView() }
            }
        }
        .navigationTitle("自动化")
    }
}
