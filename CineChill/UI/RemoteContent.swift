import SwiftUI

/// 让子视图能主动触发所在页面的重新加载。
public struct Reload {
    let action: () async -> Void

    public func callAsFunction() async { await action() }

    public func fire() {
        Task { await action() }
    }
}

/// 通用「拉取 JSON → 渲染列表」容器。绝大多数模块页面都基于它，
/// 统一处理加载中、失败重试、下拉刷新与 401 上抛。
public struct RemoteList<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let load: () async throws -> JSONValue
    private let content: (JSONValue, Reload) -> Content

    @State private var value: JSONValue = .null
    @State private var phase: Phase = .loading
    @EnvironmentObject private var session: AppSession

    private enum Phase: Equatable {
        case loading
        case ready
        case failed(String)
    }

    public init(title: String,
                subtitle: String? = nil,
                load: @escaping () async throws -> JSONValue,
                @ViewBuilder content: @escaping (JSONValue, Reload) -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.load = load
        self.content = content
    }

    public var body: some View {
        List {
            if let subtitle, !subtitle.isEmpty, phase == .ready {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
            switch phase {
            case .loading:
                LoadingRow()
            case .failed(let message):
                FailureRow(message: message) { Task { await reload() } }
            case .ready:
                content(value, Reload { await reload() })
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .refreshable { await reload() }
        .task {
            if phase == .loading { await reload() }
        }
    }

    private func reload() async {
        do {
            let fetched = try await load()
            value = fetched
            phase = .ready
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            if case .cancelled = error { return }
            phase = .failed(error.errorDescription ?? "加载失败")
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

/// 与 `RemoteList` 相同的加载语义，但内容放在可滚动容器里（用于海报墙、仪表盘等）。
public struct RemoteScroll<Content: View>: View {
    private let title: String
    private let load: () async throws -> JSONValue
    private let content: (JSONValue, Reload) -> Content

    @State private var value: JSONValue = .null
    @State private var phase: Phase = .loading
    @EnvironmentObject private var session: AppSession

    private enum Phase: Equatable {
        case loading
        case ready
        case failed(String)
    }

    public init(title: String,
                load: @escaping () async throws -> JSONValue,
                @ViewBuilder content: @escaping (JSONValue, Reload) -> Content) {
        self.title = title
        self.load = load
        self.content = content
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch phase {
                case .loading:
                    HStack {
                        Spacer()
                        ProgressView().padding(.vertical, 60)
                        Spacer()
                    }
                case .failed(let message):
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(message)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("重新加载") { Task { await reload() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                case .ready:
                    content(value, Reload { await reload() })
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(title)
        .refreshable { await reload() }
        .task {
            if phase == .loading { await reload() }
        }
    }

    private func reload() async {
        do {
            value = try await load()
            phase = .ready
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            if case .cancelled = error { return }
            phase = .failed(error.errorDescription ?? "加载失败")
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

public struct LoadingRow: View {
    public init() {}
    public var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("加载中…").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
        .listRowSeparator(.hidden)
    }
}

public struct FailureRow: View {
    let message: String
    let retry: () -> Void

    public init(message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("加载失败", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("重试", action: retry)
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 6)
    }
}

public struct EmptyRow: View {
    let text: String

    public init(_ text: String = "暂无数据") { self.text = text }

    public var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 18)
    }
}

/// 执行写操作（POST/DELETE）并给出统一反馈。
@MainActor
public final class ActionRunner: ObservableObject {
    @Published public var isRunning = false
    @Published public var alertText: String?
    @Published public var alertIsError = false
    /// 最近一次成功返回的原始响应，便于「测试类」页面直接展示结果。
    @Published public var lastResult: JSONValue = .null

    public init() {}

    public func run(_ successText: String? = nil,
                    operation: @escaping () async throws -> JSONValue,
                    onSuccess: (() async -> Void)? = nil) {
        guard !isRunning else { return }
        isRunning = true
        Task {
            do {
                let result = try await operation()
                isRunning = false
                lastResult = result
                if result.isSuccessFlag == false {
                    alertIsError = true
                    alertText = result.errorMessage ?? "操作未成功（服务端未提供错误原因）"
                } else {
                    alertIsError = false
                    if let successText { alertText = successText }
                    await onSuccess?()
                }
            } catch {
                isRunning = false
                alertIsError = true
                alertText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

public extension View {
    /// 绑定 `ActionRunner` 的提示弹窗与执行中遮罩。
    func actionFeedback(_ runner: ActionRunner) -> some View {
        modifier(ActionFeedbackModifier(runner: runner))
    }
}

struct ActionFeedbackModifier: ViewModifier {
    @ObservedObject var runner: ActionRunner

    func body(content: Content) -> some View {
        content
            .disabled(runner.isRunning)
            .overlay {
                if runner.isRunning {
                    ZStack {
                        Color.black.opacity(0.08).ignoresSafeArea()
                        ProgressView()
                            .padding(18)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .alert(runner.alertIsError ? "操作失败" : "已完成",
                   isPresented: Binding(get: { runner.alertText != nil },
                                        set: { if !$0 { runner.alertText = nil } })) {
                Button("好", role: .cancel) { runner.alertText = nil }
            } message: {
                Text(runner.alertText ?? "")
            }
    }
}
