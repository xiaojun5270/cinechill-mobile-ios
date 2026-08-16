import SwiftUI

/// 应用锁的门：锁定时盖住整个界面，切后台时用品牌页遮住系统快照。
struct AppLockGate<Content: View>: View {
    @EnvironmentObject private var lock: AppLock
    @Environment(\.scenePhase) private var scenePhase

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
                .allowsHitTesting(!lock.isLocked)
            if lock.isLocked {
                LockScreen()
                    .transition(.opacity)
            } else if lock.isObscured {
                BrandCurtain(caption: nil)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: lock.isLocked)
        .onChange(of: scenePhase) { _, phase in
            lock.note(phase: phase)
        }
    }
}

/// 锁屏：进入时自动唤起验证，失败后可手动重试。
struct LockScreen: View {
    @EnvironmentObject private var lock: AppLock
    @State private var didTry = false

    var body: some View {
        BrandCurtain(caption: "CineChill 已锁定") {
            VStack(spacing: 14) {
                if lock.isVerifying {
                    ProgressView()
                } else {
                    Button {
                        Task { await lock.unlock() }
                    } label: {
                        Label("用\(lock.availability.title)解锁",
                              systemImage: lock.availability.systemImage)
                            .font(.headline)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                }
                if let error = lock.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .task {
            guard !didTry else { return }
            didTry = true
            await lock.unlock()
        }
    }
}

/// 品牌遮罩：图标 + 名称，用于锁屏底层和后台快照遮挡。
struct BrandCurtain<Footer: View>: View {
    let caption: String?
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "play.circle")
                    .font(.system(size: 68, weight: .light))
                    .foregroundStyle(Color.accentColor)
                if let caption {
                    Text(caption)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                footer()
            }
        }
    }
}

extension BrandCurtain where Footer == EmptyView {
    init(caption: String?) {
        self.init(caption: caption) { EmptyView() }
    }
}

/// 设置里的应用锁开关。
struct AppLockView: View {
    @EnvironmentObject private var lock: AppLock
    @State private var working = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { lock.isEnabled },
                    set: { newValue in
                        guard !working else { return }
                        if newValue {
                            working = true
                            Task {
                                await lock.enable()
                                working = false
                            }
                        } else {
                            lock.disable()
                        }
                    })) {
                        Label("启用应用锁", systemImage: lock.availability.systemImage)
                    }
                    .disabled(!lock.availability.isUsable || working)
                if case .unavailable(let reason) = lock.availability {
                    Label(reason, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("验证方式：\(lock.availability.title)")
            } footer: {
                Text("开启前会先验证一次，避免把自己锁在外面。系统弹窗里可以选择改用设备密码。")
            }

            if lock.isEnabled {
                Section {
                    Picker("离开后锁定", selection: Binding(
                        get: { lock.delay },
                        set: { lock.update(delay: $0) })) {
                        ForEach(AppLock.Delay.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    Button {
                        lock.lockNow()
                    } label: {
                        Label("立即锁定", systemImage: "lock")
                    }
                } footer: {
                    Text("切到后台或多任务切换器时，界面会被品牌遮罩挡住，系统截图里不会留下内容。")
                }
            }

            Section {
                Text("应用锁只挡住界面。服务器密码依旧存放在系统钥匙串里，由设备密码与硬件加密保护，App 本身不会额外加密或解密它。")
                Text("如果你从没在系统设置里设过设备密码，iOS 不提供任何本地验证方式，这个开关也就无法打开。")
            } header: {
                Text("它保护什么、不保护什么")
            }
        }
        .navigationTitle("应用锁")
        .onAppear { lock.refreshAvailability() }
    }
}
