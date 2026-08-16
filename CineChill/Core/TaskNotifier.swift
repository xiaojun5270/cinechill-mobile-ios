import BackgroundTasks
import Foundation
import UserNotifications

/// 后台刷新的任务标识，必须与 Info.plist 里 `BGTaskSchedulerPermittedIdentifiers` 一致。
let taskRefreshIdentifier = "com.cinechill.mobile.taskrefresh"

/// 任务完成通知的核心逻辑。
///
/// 全部做成 nonisolated 的静态函数，好处是前台（View 里手动检查）与后台（`backgroundTask`
/// 回调，不在主线程）能走同一套代码，也不用把 `AppSession` 拖进后台上下文。
enum TaskWatch {

    enum Key {
        static let enabled = "notify.tasks.enabled"
        static let background = "notify.tasks.background"
        static let snapshot = "notify.tasks.snapshot"
        static let lastCheck = "notify.tasks.lastCheck"
        static let lastResult = "notify.tasks.lastResult"
    }

    /// 从 `/api/progress` 里认出的一个任务。
    struct Item: Equatable {
        let key: String
        let name: String
        let status: String
        let percent: Double?

        /// 是否已经跑完（含成功与失败）。
        var isFinished: Bool {
            let s = status.lowercased()
            if TaskWatch.doneWords.contains(where: { s.contains($0) }) { return true }
            if TaskWatch.failWords.contains(where: { s.contains($0) }) { return true }
            if let percent, percent >= 100 { return true }
            return false
        }

        var isFailed: Bool {
            let s = status.lowercased()
            return TaskWatch.failWords.contains(where: { s.contains($0) })
        }
    }

    static let doneWords = ["done", "finish", "complete", "success", "ok", "完成", "成功"]
    static let failWords = ["fail", "error", "abort", "cancel", "stopped", "失败", "错误", "中止", "取消"]

    // MARK: - 解析

    /// 服务端没声明结构，这里兼容三种常见形态：
    /// `{running: [...]}`、`{tasks: [...]}`、以及直接用任务名做键的字典。
    static func items(from progress: JSONValue) -> [Item] {
        var out: [Item] = []
        let arrays = progress.list("running", "tasks", "items", "list")
        if !arrays.isEmpty {
            for (index, node) in arrays.enumerated() {
                out.append(item(from: node, fallbackKey: "index-\(index)"))
            }
            return out
        }
        if let object = progress.object {
            for (key, node) in object.sorted(by: { $0.key < $1.key }) {
                guard node.object != nil else { continue }
                out.append(item(from: node, fallbackKey: key))
            }
        }
        return out
    }

    private static func item(from node: JSONValue, fallbackKey: String) -> Item {
        let name = node.first(of: "name", "title", "task", "task_name", "id").displayString ?? fallbackKey
        let identifier = node.first(of: "id", "task_id", "key", "uuid").displayString ?? name
        let status = node.first(of: "status", "state", "stage", "phase").displayString ?? ""
        var percent = node.first(of: "percent", "progress", "percentage").double
        if percent == nil,
           let done = node.first(of: "done", "current", "finished").double,
           let total = node.first(of: "total", "count", "all").double, total > 0 {
            percent = done / total * 100
        }
        return Item(key: "\(fallbackKey)|\(identifier)", name: name, status: status, percent: percent)
    }

    // MARK: - 快照与比对

    static func snapshot() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: Key.snapshot) as? [String: String] ?? [:]
    }

    static func save(snapshot: [String: String]) {
        UserDefaults.standard.set(snapshot, forKey: Key.snapshot)
    }

    /// 与上次快照比对，返回这一轮「刚刚结束」的任务。
    ///
    /// 判定条件：上一轮在跑，这一轮已完成或已经从列表里消失。首次运行只建立基线、不发通知，
    /// 否则一开启就会把历史任务全播一遍。
    static func changes(current items: [Item], previous: [String: String],
                        isFirstRun: Bool) -> (finished: [Item], failed: [Item], snapshot: [String: String]) {
        var next: [String: String] = [:]
        var finished: [Item] = []
        var failed: [Item] = []

        for item in items {
            let state = item.isFinished ? "finished" : "running"
            next[item.key] = "\(state)|\(item.name)"
            guard !isFirstRun, let before = previous[item.key], before.hasPrefix("running") else { continue }
            if item.isFailed {
                failed.append(item)
            } else if item.isFinished {
                finished.append(item)
            }
        }

        // 上一轮在跑、这一轮直接消失的，按完成处理（服务端跑完就清出列表）
        if !isFirstRun {
            let currentKeys = Set(items.map(\.key))
            for (key, value) in previous where value.hasPrefix("running") && !currentKeys.contains(key) {
                let name = value.split(separator: "|", maxSplits: 1).last.map(String.init) ?? "任务"
                finished.append(Item(key: key, name: name, status: "done", percent: 100))
            }
        }

        return (finished, failed, next)
    }

    // MARK: - 通知

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func notify(finished: [Item], failed: [Item]) async {
        guard !finished.isEmpty || !failed.isEmpty else { return }
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        for item in failed {
            await post(title: "任务未完成", body: "\(item.name)：\(item.status)", id: "fail-\(item.key)")
        }
        if finished.count == 1, let only = finished.first {
            await post(title: "任务完成", body: only.name, id: "done-\(only.key)")
        } else if finished.count > 1 {
            let names = finished.prefix(3).map(\.name).joined(separator: "、")
            let more = finished.count > 3 ? " 等 \(finished.count) 个任务" : ""
            await post(title: "任务完成", body: names + more, id: "done-batch-\(Date().timeIntervalSince1970)")
        }
    }

    private static func post(title: String, body: String, id: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 一轮检查

    /// 拉一次进度、比对、必要时发通知。返回给界面显示的一句话结果。
    @discardableResult
    static func run(api: CineChillAPI, isFirstRun: Bool = false) async -> String {
        do {
            let progress = try await api.tasks.getProgress()
            let items = items(from: progress)
            let previous = snapshot()
            let firstRun = isFirstRun || previous.isEmpty
            let result = changes(current: items, previous: previous, isFirstRun: firstRun)
            save(snapshot: result.snapshot)
            await notify(finished: result.finished, failed: result.failed)
            let running = items.filter { !$0.isFinished }.count
            let summary: String
            if firstRun {
                summary = "已建立基线，当前 \(running) 个任务在跑"
            } else if result.finished.isEmpty && result.failed.isEmpty {
                summary = "无变化，当前 \(running) 个任务在跑"
            } else {
                summary = "完成 \(result.finished.count) 个，异常 \(result.failed.count) 个"
            }
            record(result: summary)
            return summary
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            record(result: "检查失败：\(message)")
            return "检查失败：\(message)"
        }
    }

    private static func record(result: String) {
        let defaults = UserDefaults.standard
        defaults.set(Date(), forKey: Key.lastCheck)
        defaults.set(result, forKey: Key.lastResult)
    }

    // MARK: - 后台刷新

    /// 后台唤醒时用存好的服务器信息自己建一个客户端。
    ///
    /// 会话 Cookie 存在 `HTTPCookieStorage.shared` 里，跨启动仍然有效；万一过期，就用钥匙串里的
    /// 密码静默登录一次。两者都不成立时安静地放弃，不打扰用户。
    static func backgroundRefresh() async {
        defer { scheduleBackgroundRefresh() }
        guard UserDefaults.standard.bool(forKey: Key.enabled),
              UserDefaults.standard.bool(forKey: Key.background) else { return }
        guard let id = ServerStore.loadActiveID(),
              let profile = ServerStore.load().first(where: { $0.id == id }),
              let url = profile.baseURL else { return }

        let client = APIClient(baseURL: url, serverID: profile.id,
                              allowInsecureTLS: profile.allowInsecureTLS)
        let api = CineChillAPI(client: client)

        do {
            _ = try await api.auth.getUserInfo()
        } catch {
            guard profile.rememberPassword,
                  let password = Keychain.read(account: profile.passwordAccount),
                  !profile.username.isEmpty else { return }
            let response = try? await api.auth.login(
                LoginRequest(username: profile.username, password: password))
            guard let response else { return }
            if let token = APIClient.extractToken(from: response) {
                client.updateToken(token)
            }
        }
        await run(api: api)
    }

    /// iOS 只承诺「有机会时」执行，间隔给 15 分钟是系统能接受的下限。
    static func scheduleBackgroundRefresh() {
        guard UserDefaults.standard.bool(forKey: Key.enabled),
              UserDefaults.standard.bool(forKey: Key.background) else { return }
        let request = BGAppRefreshTaskRequest(identifier: taskRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    static func cancelBackgroundRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskRefreshIdentifier)
    }
}

/// App 在前台时，系统默认不弹横幅。装上这个代理，前台也能看到「任务完成」。
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationPresenter()

    /// 注册代理要在 App 启动早期做一次。
    static func install() {
        UNUserNotificationCenter.current().delegate = shared
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}

/// 任务通知的界面状态。
@MainActor
public final class TaskNotifier: ObservableObject {
    @Published public private(set) var isEnabled: Bool
    @Published public private(set) var backgroundEnabled: Bool
    @Published public private(set) var authorization: UNAuthorizationStatus = .notDetermined
    @Published public private(set) var isWorking = false
    @Published public var lastResult: String?
    @Published public var lastCheck: Date?

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: TaskWatch.Key.enabled)
        backgroundEnabled = defaults.bool(forKey: TaskWatch.Key.background)
        lastResult = defaults.string(forKey: TaskWatch.Key.lastResult)
        lastCheck = defaults.object(forKey: TaskWatch.Key.lastCheck) as? Date
    }

    public func refreshAuthorization() async {
        authorization = await TaskWatch.authorizationStatus()
    }

    /// 打开开关：先要通知权限，拿不到就不打开，免得开了却收不到。
    @discardableResult
    public func enable() async -> Bool {
        isWorking = true
        var granted = await TaskWatch.authorizationStatus() == .authorized
        if !granted {
            granted = await TaskWatch.requestAuthorization()
        }
        await refreshAuthorization()
        isWorking = false
        guard granted else { return false }
        isEnabled = true
        defaults.set(true, forKey: TaskWatch.Key.enabled)
        TaskWatch.scheduleBackgroundRefresh()
        return true
    }

    public func disable() {
        isEnabled = false
        defaults.set(false, forKey: TaskWatch.Key.enabled)
        defaults.removeObject(forKey: TaskWatch.Key.snapshot)
        TaskWatch.cancelBackgroundRefresh()
    }

    public func setBackground(_ on: Bool) {
        backgroundEnabled = on
        defaults.set(on, forKey: TaskWatch.Key.background)
        if on {
            TaskWatch.scheduleBackgroundRefresh()
        } else {
            TaskWatch.cancelBackgroundRefresh()
        }
    }

    /// 前台检查一次。
    public func check(api: CineChillAPI) async {
        guard !isWorking else { return }
        isWorking = true
        let summary = await TaskWatch.run(api: api)
        lastResult = summary
        lastCheck = Date()
        isWorking = false
    }

    /// 前台轮询：开着通知时，每 45 秒对一次进度，这样不进后台也能收到提示。
    public func pollWhileActive(session: AppSession) async {
        while !Task.isCancelled {
            if isEnabled, let api = session.api, session.authState == .loggedIn {
                _ = await TaskWatch.run(api: api)
                lastResult = defaults.string(forKey: TaskWatch.Key.lastResult)
                lastCheck = Date()
            }
            try? await Task.sleep(nanoseconds: 45 * 1_000_000_000)
        }
    }
}
