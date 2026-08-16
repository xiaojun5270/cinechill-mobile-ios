import SwiftUI

/// 服务端全局参数：连接信息、代理、元数据凭据、公开地址和日志级别。
struct ServerConfigView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    @State private var proxyAddress = ""
    @State private var tmdbKey = ""
    @State private var doubanCookie = ""
    @State private var publicBaseURL = ""
    @State private var logLevel = "INFO"
    @State private var proxyResult: JSONValue = .null
    @State private var confirmRestart = false

    private let logLevels = ["INFO", "DEBUG", "WARNING", "ERROR", "CRITICAL"]

    var body: some View {
        RemoteList(title: "服务端参数") {
            let api = try session.requireAPI()
            return try await api.server.loadConfig()
        } content: { value, reload in
            let config = Self.unwrap(value)

            Section("连接信息") {
                KeyValueRow("版本", session.serverVersion
                            ?? config.deepFirst(of: "version", "app_version").displayString
                            ?? "未知")
                if let profile = session.activeServer {
                    KeyValueRow("服务器地址", profile.baseURLString, monospaced: true)
                    KeyValueRow("连接端口", String(profile.port))
                }
                if let dataDirectory = config.deepFirst(of: "data_dir", "config_dir").displayString,
                   !dataDirectory.isEmpty {
                    KeyValueRow("数据目录", dataDirectory, monospaced: true)
                }
                if let language = config.deepFirst(of: "tmdb_language", "language").displayString,
                   !language.isEmpty {
                    KeyValueRow("TMDb 语言", language)
                }
            }

            Section {
                TextField("http://127.0.0.1:7890", text: $proxyAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                Button {
                    testProxy()
                } label: {
                    Label("测试代理连通性", systemImage: "network")
                }
                .disabled(proxyAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button {
                    save(["proxy_url": .string(proxyAddress)],
                         successText: "代理设置已保存")
                } label: {
                    Label("保存代理设置", systemImage: "square.and.arrow.down")
                }
                proxyTestResult
            } header: {
                Text("网络代理")
            } footer: {
                Text("TMDB、豆瓣和 DockerHub 等外部请求会使用此代理；清空并保存可恢复直连。")
            }

            Section {
                SecureField("TMDB API Key", text: $tmdbKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("豆瓣 Cookie", text: $doubanCookie)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    save([
                        "tmdb_key": .string(tmdbKey),
                        "douban_cookie": .string(doubanCookie),
                    ], successText: "元数据设置已保存")
                } label: {
                    Label("保存元数据设置", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("TMDB 与豆瓣")
            } footer: {
                Text("凭据默认隐藏。TMDB 用于媒体识别和封面，豆瓣 Cookie 用于豆瓣发现源。")
            }

            Section {
                TextField("https://example.com", text: $publicBaseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                Button {
                    save(["app_public_base_url": .string(publicBaseURL)],
                         successText: "公开访问地址已保存")
                } label: {
                    Label("保存公开地址", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("公开访问地址")
            } footer: {
                Text("通知消息中的图片和回调链接会使用此地址。")
            }

            Section {
                Picker("日志级别", selection: $logLevel) {
                    ForEach(logLevels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .pickerStyle(.menu)
                Button {
                    save(["log_level": .string(logLevel)],
                         successText: "日志级别已保存")
                } label: {
                    Label("保存日志设置", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("运行日志")
            } footer: {
                Text("排查结束后建议恢复 INFO，避免 DEBUG 日志长期占用存储空间。")
            }

            Section("配置状态") {
                KeyValueRow("网络代理", Self.configured(proxyAddress, empty: "直连"))
                KeyValueRow("TMDB API Key", Self.configured(tmdbKey))
                KeyValueRow("豆瓣 Cookie", Self.configured(doubanCookie))
                KeyValueRow("公开访问地址", publicBaseURL.isEmpty ? "未配置" : publicBaseURL)
                KeyValueRow("日志级别", logLevel)
            }

            Section {
                NavigationLink {
                    ServerAdvancedConfigView()
                } label: {
                    Label("高级配置", systemImage: "slider.horizontal.3")
                }
                Button {
                    confirmRestart = true
                } label: {
                    Label("重启服务端", systemImage: "arrow.clockwise.circle")
                }
                .foregroundStyle(.red)
            } footer: {
                Text("重启会中断正在进行的整理、同步与上传任务，App 需要重新连接。")
            }
            .confirmationDialog("重启服务端？", isPresented: $confirmRestart, titleVisibility: .visible) {
                Button("重启", role: .destructive) {
                    runner.run("已请求重启", operation: {
                        let api = try session.requireAPI()
                        return try await api.server.restartServer()
                    }, onSuccess: { await reload() })
                }
                Button("取消", role: .cancel) {}
            }
            .task(id: config) {
                apply(config)
            }
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private var proxyTestResult: some View {
        if proxyResult.isNull == false {
            let result = proxyResult
            KeyValueRow("测试状态", result.first(of: "status", "ok", "success"))
            if let latency = result.first(of: "latency_ms", "latency", "elapsed_ms").displayString {
                KeyValueRow("响应耗时", "\(latency) ms")
            }
            if let target = result.first(of: "target_url", "target").displayString {
                KeyValueRow("测试目标", target, monospaced: true)
            }
            if let message = result.first(of: "message", "detail").displayString {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func apply(_ config: JSONValue) {
        proxyAddress = config["proxy_url"].string ?? ""
        tmdbKey = config["tmdb_key"].string ?? ""
        doubanCookie = config["douban_cookie"].string ?? ""
        publicBaseURL = config["app_public_base_url"].string ?? ""
        logLevel = config["log_level"].string?.uppercased() ?? "INFO"
    }

    private func testProxy() {
        proxyResult = .null
        runner.run("代理连接测试成功", operation: {
            let api = try session.requireAPI()
            return try await api.server.testProxyConnection(
                .object(["proxy_url": .string(proxyAddress)]))
        }, onSuccess: {
            proxyResult = runner.lastResult
        })
    }

    private func save(_ fields: [String: JSONValue], successText: String) {
        runner.run(successText) {
            let api = try session.requireAPI()
            return try await api.server.saveConfig(.object(fields))
        }
    }

    private static func configured(_ value: String, empty: String = "未配置") -> String {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return empty }
        return "已配置"
    }

    static func unwrap(_ value: JSONValue) -> JSONValue {
        for key in ["config", "data", "settings"] {
            if value[key].object != nil { return value[key] }
        }
        return value
    }
}

/// 服务端 config.json 全量高级编辑，未知字段会在读取后原样保留。
struct ServerAdvancedConfigView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        JSONConfigScreen(
            title: "服务端高级配置",
            note: "对应 Web 后台的 config.json。敏感字段默认隐藏；保存前请确认所有字段无误。",
            unwrapKeys: ["config", "data", "settings"],
            load: {
                let api = try session.requireAPI()
                return try await api.server.loadConfig()
            },
            save: { edited in
                let api = try session.requireAPI()
                return try await api.server.saveConfig(edited)
            })
    }
}
