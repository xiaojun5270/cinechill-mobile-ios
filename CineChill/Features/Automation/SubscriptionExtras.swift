import SwiftUI

/// 订阅事件流。
struct SubscriptionEventsView: View {
    @EnvironmentObject private var session: AppSession
    @State private var eventType = ""
    @State private var queryKey = 0

    private let types = ["", "matched", "subscribed", "downloaded", "failed"]

    var body: some View {
        RemoteList(title: "订阅事件") {
            let api = try session.requireAPI()
            return try await api.subscriptions.listSubscriptionEvents(
                limit: 200,
                eventType: eventType.isEmpty ? nil : eventType,
                subscriptionIds: nil, tmdbId: nil, mediaType: nil)
        } content: { value, _ in
            Section("筛选") {
                Picker("事件类型", selection: $eventType) {
                    ForEach(types, id: \.self) { Text($0.isEmpty ? "全部" : $0).tag($0) }
                }
                .onChange(of: eventType) { _, _ in queryKey += 1 }
            }
            let events = value.list("events", "items")
            if events.isEmpty { EmptyRow("没有事件") }
            ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.first(of: "title", "name", "media_title").displayString ?? "—")
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        if let type = event.first(of: "event_type", "type").displayString {
                            StatusBadge(type, tone: badgeTone(for: type))
                        }
                    }
                    if let message = event.first(of: "message", "detail", "description").displayString {
                        Text(message).font(.caption2).foregroundStyle(.secondary).lineLimit(3)
                    }
                    if let time = event.first(of: "created_at", "time", "timestamp").displayString {
                        Text(Fmt.relative(.string(time))).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .id(queryKey)
    }
}

/// 订阅动态。
struct SubscriptionActivityView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        RemoteList(title: "订阅动态") {
            let api = try session.requireAPI()
            return try await api.subscriptions.getSubscriptionActivity(
                subscriptionIds: nil, tmdbId: nil, mediaType: nil, title: nil, limit: 100)
        } content: { value, _ in
            let items = value.list("activity", "items", "records")
            if items.isEmpty {
                Section { JSONFieldList(value: value) }
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.first(of: "title", "name").displayString ?? "—")
                            .font(.subheadline)
                        if let summary = item.first(of: "summary", "message", "status").displayString {
                            Text(summary).font(.caption2).foregroundStyle(.secondary)
                        }
                        if let time = item.first(of: "updated_at", "created_at", "time").displayString {
                            Text(Fmt.relative(.string(time))).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }
}

/// MoviePilot：连接配置、连通性测试、订阅列表与退订。
struct MoviePilotView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    var body: some View {
        RemoteList(title: "MoviePilot") {
            let api = try session.requireAPI()
            let config = await Probe.json { try await api.moviePilot.getMpConfig() }
            let subs = await Probe.json { try await api.moviePilot.mpListSubscriptions() }
            return JSONValue.object(["config": config, "subscriptions": subs])
        } content: { value, reload in
            Section("连接") {
                KeyValueRow("地址", value["config"].deepFirst(of: "mp_url", "url"))
                KeyValueRow("用户名", value["config"].deepFirst(of: "mp_username", "username"))
                NavigationLink {
                    MoviePilotConfigView()
                } label: {
                    Label("修改连接配置", systemImage: "slider.horizontal.3")
                }
                Button {
                    runner.run("连接正常") {
                        let api = try session.requireAPI()
                        return try await api.moviePilot.testMpConnection()
                    }
                } label: {
                    Label("测试连接", systemImage: "bolt.horizontal")
                }
            }

            let subs = value["subscriptions"].list("subscriptions", "items", "data")
            Section("订阅（\(subs.count)）") {
                if subs.isEmpty { EmptyRow("没有订阅") }
                ForEach(Array(subs.enumerated()), id: \.offset) { _, sub in
                    subscriptionRow(sub, reload: reload)
                }
            }
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func subscriptionRow(_ sub: JSONValue, reload: Reload) -> some View {
        let tmdbID = sub.deepFirst(of: "tmdbid", "tmdb_id").int
        let type = sub.first(of: "type", "type_name", "media_type").displayString ?? "电影"
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(sub.first(of: "name", "title").displayString ?? "—")
                    .font(.subheadline)
                Spacer()
                StatusBadge(type, tone: .info)
            }
            HStack(spacing: 8) {
                if let year = sub.first(of: "year").displayString { Text(year) }
                if let season = sub.first(of: "season").int, season > 0 { Text("第 \(season) 季") }
                if let tmdbID { Text("TMDB \(tmdbID)") }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            if let tmdbID {
                HStack(spacing: 16) {
                    Button("检查状态") {
                        runner.run(nil) {
                            let api = try session.requireAPI()
                            return try await api.moviePilot.mpCheckSubscribe(
                                tmdbid: tmdbID, typeName: type, season: sub.first(of: "season").int)
                        }
                    }
                    Button("退订") {
                        runner.run("已退订", operation: {
                            let api = try session.requireAPI()
                            return try await api.moviePilot.mpUnsubscribe(
                                tmdbid: tmdbID, typeName: type, season: sub.first(of: "season").int)
                        }, onSuccess: { await reload() })
                    }
                    .foregroundStyle(.red)
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
        }
    }
}

/// MoviePilot 连接配置。
struct MoviePilotConfigView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var url = ""
    @State private var username = ""
    @State private var password = ""
    @State private var loaded = false

    var body: some View {
        Form {
            Section("连接信息") {
                TextField("MoviePilot 地址", text: $url)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("用户名", text: $username)
                    .textInputAutocapitalization(.never)
                SecureField("密码（留空表示不修改）", text: $password)
            }
            Section {
                Button("保存") {
                    runner.run("已保存") {
                        let api = try session.requireAPI()
                        return try await api.moviePilot.saveMpConfig(
                            MoviePilotConfigModel(mpUrl: url, mpUsername: username, mpPassword: password))
                    }
                }
                .disabled(url.isEmpty)
            } footer: {
                Text("地址形如 http://192.168.1.10:3000。密码保存在服务端配置中。")
            }
        }
        .navigationTitle("MoviePilot 配置")
        .actionFeedback(runner)
        .task {
            guard !loaded, let api = session.api else { return }
            loaded = true
            let config = await Probe.json { try await api.moviePilot.getMpConfig() }
            url = config.deepFirst(of: "mp_url", "url").string ?? ""
            username = config.deepFirst(of: "mp_username", "username").string ?? ""
        }
    }
}
