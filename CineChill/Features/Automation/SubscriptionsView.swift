import SwiftUI

/// 订阅中心：订阅源管理 + 事件与动态。
struct SubscriptionsView: View {
    var body: some View {
        List {
            Section {
                ModuleRow(title: "订阅源",
                          subtitle: "新增、编辑、同步、删除",
                          systemImage: "antenna.radiowaves.left.and.right",
                          tint: .pink) { SubscriptionSourcesView() }
                ModuleRow(title: "订阅事件",
                          subtitle: "按类型查看订阅事件流",
                          systemImage: "list.bullet.indent",
                          tint: .orange) { SubscriptionEventsView() }
                ModuleRow(title: "订阅动态",
                          subtitle: "最近的匹配与入库动态",
                          systemImage: "waveform.path.ecg",
                          tint: .green) { SubscriptionActivityView() }
            }
        }
        .navigationTitle("订阅中心")
    }
}

/// 订阅源列表。
struct SubscriptionSourcesView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var creating = false
    @State private var editing: SubscriptionSourceDraft?

    var body: some View {
        RemoteList(title: "订阅源") {
            let api = try session.requireAPI()
            return try await api.subscriptions.listSubscriptionRssSources()
        } content: { value, reload in
            let sources = value.list("sources", "items")
            if sources.isEmpty { EmptyRow("还没有订阅源") }
            ForEach(Array(sources.enumerated()), id: \.offset) { _, source in
                sourceRow(source, reload: reload)
            }
            Section {
                Button {
                    creating = true
                } label: {
                    Label("新增订阅源", systemImage: "plus.circle")
                }
            }
            .sheet(isPresented: $creating) {
                NavigationStack {
                    SubscriptionSourceEditorView(draft: SubscriptionSourceDraft()) { reload.fire() }
                }
            }
            .sheet(item: $editing) { draft in
                NavigationStack {
                    SubscriptionSourceEditorView(draft: draft) { reload.fire() }
                }
            }
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func sourceRow(_ source: JSONValue, reload: Reload) -> some View {
        let id = source.first(of: "id", "source_id").displayString ?? ""
        let enabled = source.first(of: "enabled").bool ?? true
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(source.first(of: "name").displayString ?? "—")
                    .font(.subheadline.weight(.medium))
                Spacer()
                StatusBadge(enabled ? "已启用" : "已停用", tone: enabled ? .good : .neutral)
            }
            if let url = source.first(of: "rss_url").displayString {
                Text(url).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            HStack(spacing: 8) {
                Text(source.first(of: "media_type").displayString == "movie" ? "电影" : "剧集")
                Text("· " + (source.first(of: "subscription_target").displayString ?? "moviepilot"))
                Text("· " + Fmt.cron(source.first(of: "cron").string))
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            HStack(spacing: 16) {
                Button("同步") {
                    runner.run("已触发同步", operation: {
                        let api = try session.requireAPI()
                        return try await api.subscriptions.syncSubscriptionRssSource(sourceId: id)
                    }, onSuccess: { await reload() })
                }
                Button(enabled ? "停用" : "启用") {
                    runner.run("已更新", operation: {
                        let api = try session.requireAPI()
                        return try await api.subscriptions.patchSubscriptionRssSource(
                            sourceId: id, RssSourcePatchPayload(enabled: !enabled))
                    }, onSuccess: { await reload() })
                }
                Button("编辑") { editing = SubscriptionSourceDraft(source) }
                Button("删除") {
                    runner.run("已删除", operation: {
                        let api = try session.requireAPI()
                        return try await api.subscriptions.deleteSubscriptionRssSource(sourceId: id)
                    }, onSuccess: { await reload() })
                }
                .foregroundStyle(.red)
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .disabled(id.isEmpty)
        }
    }
}

struct SubscriptionSourceDraft: Identifiable {
    var id: String
    var name: String
    var rssURL: String
    var mediaType: String
    var target: String
    var cron: String
    var enabled: Bool

    init() {
        id = ""
        name = ""
        rssURL = ""
        mediaType = "tv"
        target = "moviepilot"
        cron = "0 */12 * * *"
        enabled = true
    }

    init(_ source: JSONValue) {
        id = source.first(of: "id", "source_id").displayString ?? ""
        name = source.first(of: "name").string ?? ""
        rssURL = source.first(of: "rss_url").string ?? ""
        mediaType = source.first(of: "media_type").string ?? "tv"
        target = source.first(of: "subscription_target").string ?? "moviepilot"
        cron = source.first(of: "cron").string ?? "0 */12 * * *"
        enabled = source.first(of: "enabled").bool ?? true
    }
}

struct SubscriptionSourceEditorView: View {
    @State var draft: SubscriptionSourceDraft
    let onSaved: () -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var runner = ActionRunner()

    private var isNew: Bool { draft.id.isEmpty }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("名称", text: $draft.name)
                TextField("RSS 地址", text: $draft.rssURL, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Cron", text: $draft.cron)
                    .textInputAutocapitalization(.never)
                Text(Fmt.cron(draft.cron)).font(.caption).foregroundStyle(.secondary)
            }
            Section("订阅") {
                Picker("媒体类型", selection: $draft.mediaType) {
                    Text("剧集").tag("tv")
                    Text("电影").tag("movie")
                }
                Picker("订阅目标", selection: $draft.target) {
                    Text("MoviePilot").tag("moviepilot")
                    Text("本地整理").tag("local")
                }
                Toggle("启用", isOn: $draft.enabled)
            }
            Section {
                Button(isNew ? "创建" : "保存") { save() }
                    .disabled(draft.name.isEmpty || draft.rssURL.isEmpty)
            }
        }
        .navigationTitle(isNew ? "新增订阅源" : "编辑订阅源")
        .actionFeedback(runner)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }
        }
    }

    private func save() {
        runner.run("已保存", operation: {
            let api = try session.requireAPI()
            if isNew {
                return try await api.subscriptions.createSubscriptionRssSource(
                    RssSourcePayload(name: draft.name, rssUrl: draft.rssURL,
                                     mediaType: draft.mediaType, subscriptionTarget: draft.target,
                                     cron: draft.cron, enabled: draft.enabled))
            }
            return try await api.subscriptions.patchSubscriptionRssSource(
                sourceId: draft.id,
                RssSourcePatchPayload(name: draft.name, rssUrl: draft.rssURL,
                                      mediaType: draft.mediaType, subscriptionTarget: draft.target,
                                      cron: draft.cron, enabled: draft.enabled))
        }, onSuccess: {
            onSaved()
            dismiss()
        })
    }
}
