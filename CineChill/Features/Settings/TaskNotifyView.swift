import SwiftUI
import UIKit
import UserNotifications

/// 任务完成通知：前台轮询 + 后台刷新，任务跑完时发一条本地通知。
struct TaskNotifyView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var notifier: TaskNotifier
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { notifier.isEnabled },
                    set: { on in
                        if on {
                            Task { await notifier.enable() }
                        } else {
                            notifier.disable()
                        }
                    })) {
                        Label("任务完成时通知我", systemImage: "bell.badge")
                    }
                    .disabled(notifier.isWorking)
                if notifier.authorization == .denied {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        Label("通知权限被拒绝，去系统设置打开", systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
            } header: {
                Text("本地通知")
            } footer: {
                Text("App 会记住上一次看到的任务状态，只在「原本在跑、现在结束」时提醒一次，不会把历史任务重播一遍。")
            }

            if notifier.isEnabled {
                Section {
                    Toggle(isOn: Binding(
                        get: { notifier.backgroundEnabled },
                        set: { notifier.setBackground($0) })) {
                            Label("允许后台检查", systemImage: "arrow.triangle.2.circlepath")
                        }
                } header: {
                    Text("后台刷新")
                } footer: {
                    Text("iOS 只承诺「有机会时」唤醒 App，间隔通常在十几分钟到数小时之间，不能当成定时器。需要在系统设置 → 通用 → 后台 App 刷新里保持开启。App 在前台时每 45 秒会自己对一次进度。")
                }

                Section {
                    Button {
                        guard let api = session.api else { return }
                        Task { await notifier.check(api: api) }
                    } label: {
                        HStack {
                            if notifier.isWorking { ProgressView().padding(.trailing, 6) }
                            Label("立即检查一次", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(notifier.isWorking || session.api == nil)
                    if let last = notifier.lastCheck {
                        KeyValueRow("上次检查", last.formatted(date: .abbreviated, time: .standard))
                    }
                    if let result = notifier.lastResult {
                        KeyValueRow("结果", result)
                    }
                } header: {
                    Text("检查")
                }
            }

            Section {
                KeyValueRow("通知权限", authorizationText)
                KeyValueRow("后台标识", taskRefreshIdentifier, monospaced: true)
            } header: {
                Text("状态")
            } footer: {
                Text("后台唤醒时会复用已有的会话 Cookie；若已过期，则用钥匙串里保存的密码静默登录一次。没有保存密码时会安静地跳过这一轮，不会弹任何东西。")
            }
        }
        .navigationTitle("任务通知")
        .glassNavigationBar()
        .task { await notifier.refreshAuthorization() }
    }

    private var authorizationText: String {
        switch notifier.authorization {
        case .authorized: return "已允许"
        case .denied: return "已拒绝"
        case .notDetermined: return "未询问"
        case .provisional: return "临时允许"
        case .ephemeral: return "临时会话"
        @unknown default: return "未知"
        }
    }
}
