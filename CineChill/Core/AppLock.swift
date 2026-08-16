import Foundation
import LocalAuthentication
import SwiftUI

/// 应用锁：回到前台时要求 Face ID / Touch ID / 设备密码，避免手机被别人拿到就能操作媒体服务器。
///
/// 只挡界面，不改变数据的存储方式：服务器密码仍旧由系统钥匙串保管。
@MainActor
public final class AppLock: ObservableObject {

    /// 回到前台后多久需要重新验证。
    public enum Delay: Int, CaseIterable, Identifiable {
        case immediately = 0
        case oneMinute = 60
        case fiveMinutes = 300
        case fifteenMinutes = 900

        public var id: Int { rawValue }

        public var title: String {
            switch self {
            case .immediately: return "立即"
            case .oneMinute: return "1 分钟后"
            case .fiveMinutes: return "5 分钟后"
            case .fifteenMinutes: return "15 分钟后"
            }
        }
    }

    /// 本机可用的验证方式。
    public enum Availability: Equatable {
        case faceID
        case touchID
        case opticID
        case passcodeOnly
        case unavailable(String)

        public var title: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            case .passcodeOnly: return "设备密码"
            case .unavailable: return "不可用"
            }
        }

        public var systemImage: String {
            switch self {
            case .faceID, .opticID: return "faceid"
            case .touchID: return "touchid"
            case .passcodeOnly: return "lock.rectangle"
            case .unavailable: return "lock.slash"
            }
        }

        public var isUsable: Bool {
            if case .unavailable = self { return false }
            return true
        }
    }

    private enum Key {
        static let enabled = "appLock.enabled"
        static let delay = "appLock.delay"
    }

    @Published public private(set) var isEnabled: Bool
    @Published public private(set) var delay: Delay
    @Published public private(set) var isLocked: Bool
    @Published public private(set) var isVerifying = false
    /// 切到后台或多任务切换器时盖住界面，避免系统快照泄露内容。
    @Published public private(set) var isObscured = false
    @Published public var lastError: String?
    @Published public private(set) var availability: Availability = .unavailable("尚未检测")

    private let defaults: UserDefaults
    private var leftAt: Date?

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let enabled = defaults.bool(forKey: Key.enabled)
        self.isEnabled = enabled
        self.delay = Delay(rawValue: defaults.integer(forKey: Key.delay)) ?? .immediately
        // 冷启动时若开着锁，先锁住再验证
        self.isLocked = enabled
        refreshAvailability()
    }

    // MARK: - 可用性

    public func refreshAvailability() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            availability = .unavailable(Self.describe(error))
            return
        }
        switch context.biometryType {
        case .faceID: availability = .faceID
        case .touchID: availability = .touchID
        case .opticID: availability = .opticID
        default: availability = .passcodeOnly
        }
    }

    private static func describe(_ error: NSError?) -> String {
        guard let error, let code = LAError.Code(rawValue: error.code) else {
            return "本机不支持生物识别或设备密码验证"
        }
        switch code {
        case .passcodeNotSet: return "请先在系统设置里设置设备密码"
        case .biometryNotEnrolled: return "尚未录入 Face ID / Touch ID，可先设置设备密码"
        case .biometryNotAvailable: return "本机不支持生物识别，或已拒绝授权"
        case .biometryLockout: return "生物识别已被锁定，请先用设备密码解锁一次"
        default: return "无法使用系统验证（错误码 \(code.rawValue)）"
        }
    }

    // MARK: - 开关

    /// 打开应用锁前先验证一次，避免把自己锁在外面。
    @discardableResult
    public func enable() async -> Bool {
        refreshAvailability()
        guard availability.isUsable else { return false }
        guard await verify(reason: "验证后开启应用锁") else { return false }
        isEnabled = true
        isLocked = false
        leftAt = nil
        defaults.set(true, forKey: Key.enabled)
        return true
    }

    public func disable() {
        isEnabled = false
        isLocked = false
        isObscured = false
        leftAt = nil
        defaults.set(false, forKey: Key.enabled)
    }

    public func update(delay newValue: Delay) {
        delay = newValue
        defaults.set(newValue.rawValue, forKey: Key.delay)
    }

    public func lockNow() {
        guard isEnabled else { return }
        leftAt = nil
        isLocked = true
    }

    // MARK: - 解锁

    public func unlock() async {
        guard isLocked, !isVerifying else { return }
        if await verify(reason: "解锁 CineChill") {
            isLocked = false
            leftAt = nil
        }
    }

    private func verify(reason: String) async -> Bool {
        isVerifying = true
        lastError = nil
        let context = LAContext()
        context.localizedFallbackTitle = ""   // 空串表示用系统默认的「输入密码」
        let outcome = await Self.evaluate(context, reason: reason)
        isVerifying = false
        switch outcome {
        case .success(let ok):
            if !ok { lastError = "验证未通过" }
            return ok
        case .failure(let error):
            let code = LAError.Code(rawValue: (error as NSError).code) ?? .authenticationFailed
            switch code {
            case .userCancel, .appCancel, .systemCancel, .userFallback:
                lastError = nil          // 用户主动取消或选了其他方式，不当成错误提示
            default:
                lastError = Self.describe(error as NSError)
            }
            return false
        }
    }

    private static func evaluate(_ context: LAContext, reason: String) async -> Result<Bool, Error> {
        await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if let error {
                    continuation.resume(returning: .failure(error))
                } else {
                    continuation.resume(returning: .success(success))
                }
            }
        }
    }

    // MARK: - 生命周期

    public func note(phase: ScenePhase) {
        switch phase {
        case .active:
            isObscured = false
            if isEnabled, !isLocked, let leftAt,
               Date().timeIntervalSince(leftAt) >= Double(delay.rawValue) {
                isLocked = true
            }
            self.leftAt = nil
        case .inactive:
            // 验证弹窗本身会让 App 变成 inactive，此时不必再盖一层
            isObscured = isEnabled && !isVerifying && !isLocked
        case .background:
            isObscured = isEnabled && !isLocked
            if leftAt == nil { leftAt = Date() }
        @unknown default:
            break
        }
    }
}
