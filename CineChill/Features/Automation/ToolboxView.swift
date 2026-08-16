import SwiftUI

/// Web 工具箱在 iOS 上的聚合入口，复用各业务页面而不复制配置逻辑。
struct ToolboxView: View {
    var body: some View {
        List {
            Section("115") {
                ModuleRow(title: "扫码获取115CK",
                          subtitle: "生成二维码并写入 115 账号配置",
                          systemImage: "qrcode.viewfinder",
                          tint: .blue) { Standalone115QRCodeView() }
                ModuleRow(title: "115 定时清空",
                          subtitle: "创建、启停并运行目录清理任务",
                          systemImage: "trash.circle",
                          tint: .teal) { Cleanup115View() }
                ModuleRow(title: "网盘资源秒传",
                          subtitle: "在来源与目标 115 账号间秒传",
                          systemImage: "icloud.and.arrow.up",
                          tint: .indigo) { Cloud115RapidView() }
                ModuleRow(title: "资源转存",
                          subtitle: "手动提交分享链接并查看转存历史",
                          systemImage: "arrow.left.arrow.right.circle",
                          tint: .pink) { TransferHistoryView() }
            }

            Section("集成") {
                ModuleRow(title: "Forward 模块",
                          subtitle: "资源库开关、搜索与转存模式",
                          systemImage: "arrowshape.turn.up.forward",
                          tint: .green) { ForwardView() }
                ModuleRow(title: "Webhook",
                          subtitle: "Emby Webhook、队列与删除同步",
                          systemImage: "point.3.connected.trianglepath.dotted",
                          tint: .brown) { WebhookView() }
                ModuleRow(title: "飞牛论坛签到",
                          subtitle: "Cookie、签到周期、通知与历史",
                          systemImage: "checkmark.seal",
                          tint: .green) { FnosSignView() }
                ModuleRow(title: "Telegram 监听",
                          subtitle: "账号登录、监听会话与自动转存",
                          systemImage: "paperplane",
                          tint: .blue) { TelegramNotifyView() }
                ModuleRow(title: "MoviePilot",
                          subtitle: "连接参数与自动订阅配置",
                          systemImage: "airplane.circle",
                          tint: .indigo) { MoviePilotConfigView() }
            }

            Section("网络与元数据") {
                ModuleRow(title: "代理配置",
                          subtitle: "外部请求代理与连通性测试",
                          systemImage: "network",
                          tint: .orange) { ServerConfigView() }
                ModuleRow(title: "TMDB 配置",
                          subtitle: "TMDB、豆瓣与服务端高级参数",
                          systemImage: "film.stack",
                          tint: .purple) { ServerAdvancedConfigView() }
            }
        }
        .navigationTitle("工具箱")
    }
}

/// 从工具箱直接打开 115 扫码页，先加载它保存 Cookie 所需的完整 302 配置。
private struct Standalone115QRCodeView: View {
    @EnvironmentObject private var session: AppSession
    @State private var config: JSONValue = .null
    @State private var loading = true
    @State private var errorText: String?

    var body: some View {
        Group {
            if loading {
                ProgressView("正在读取 115 配置…")
            } else if let errorText {
                ContentUnavailableView {
                    Label("配置读取失败", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorText)
                } actions: {
                    Button("重试") { Task { await load() } }
                }
            } else {
                Qrcode115LoginView(config: Config302View.unwrap(config),
                                   reload: Reload { await load(force: true) },
                                   title: "扫码获取115CK")
            }
        }
        .navigationTitle("扫码获取115CK")
        .task { await load() }
    }

    private func load(force: Bool = false) async {
        guard force || loading || errorText != nil else { return }
        loading = true
        errorText = nil
        do {
            let api = try session.requireAPI()
            config = try await api.config302.getConfig302()
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            errorText = error.errorDescription ?? "配置读取失败"
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }
}
