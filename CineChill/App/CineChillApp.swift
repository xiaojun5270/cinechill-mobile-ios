import SwiftUI

@main
struct CineChillApp: App {
    @StateObject private var session = AppSession()
    @StateObject private var lock = AppLock()
    @StateObject private var favorites = ModuleFavorites()
    @StateObject private var notifier = TaskNotifier()

    init() {
        // 导航栏 / 标签栏材质要在第一个栏创建之前装好
        GlassChrome.install()
        // 前台也要能看到任务完成的横幅
        NotificationPresenter.install()
    }

    var body: some Scene {
        WindowGroup {
            AppLockGate {
                RootView()
            }
            .environmentObject(session)
            .environmentObject(lock)
            .environmentObject(favorites)
            .environmentObject(notifier)
            .task {
                await notifier.pollWhileActive(session: session)
            }
        }
        // 后台唤醒时对一次任务进度；系统只在合适的时机调用，不保证间隔
        .backgroundTask(.appRefresh(taskRefreshIdentifier)) {
            await TaskWatch.backgroundRefresh()
        }
    }
}
