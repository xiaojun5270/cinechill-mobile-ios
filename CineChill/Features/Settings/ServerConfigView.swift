import SwiftUI

/// 服务端参数：config.json 概览、代理测试、高级编辑、重启。
struct ServerConfigView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var proxyAddress = ""
    @State private var confirmRestart = false

    var body: some View {
        RemoteList(title: "服务端参数") {
            let api = try session.requireAPI()
            return try await api.server.loadConfig()
        } content: { value, reload in
            let config = Self.unwrap(value)

            Section("概览") {
                KeyValueRow("版本", config.deepFirst(of: "version", "app_version"))
                KeyValueRow("监听端口", config.deepFirst(of: "port", "listen_port"))
                KeyValueRow("数据目录", config.deepFirst(of: "data_dir", "config_dir"))
                KeyValueRow("日志级别", config.deepFirst(of: "log_level"))
                KeyValueRow("TMDb 语言", config.deepFirst(of: "tmdb_language", "language"))
            }

            Section {
                TextField("代理地址（http://host:port）", text: $proxyAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    runner.run("代理可用") {
                        let api = try session.requireAPI()
                        return try await api.server.testProxyConnection(
                            .object(["proxy": .string(proxyAddress), "url": .string(proxyAddress)]))
                    }
                } label: {
                    Label("测试代理连通性", systemImage: "network")
                }
                .disabled(proxyAddress.isEmpty)
                if runner.lastResult.isNull == false {
                    JSONFieldList(value: runner.lastResult)
                }
            } header: {
                Text("网络代理")
            } footer: {
                Text("留空的代理不会被保存，这里只做连通性检测；正式生效需要在高级配置中写入代理字段。")
            }

            Section("全部字段") {
                if config.sortedPairs.isEmpty { EmptyRow("服务端没有返回配置字段") }
                JSONFieldList(value: config)
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
                JSONInspector(value: value)
            } footer: {
                Text("重启会中断正在进行的整理、同步与上传任务，App 需要重新连接。字段修改请在高级配置页面完成。")
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
        }
        .actionFeedback(runner)
    }

    static func unwrap(_ value: JSONValue) -> JSONValue {
        for key in ["config", "data", "settings"] {
            if value[key].object != nil { return value[key] }
        }
        return value
    }
}

/// 服务端 config.json 全量高级编辑。
struct ServerAdvancedConfigView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        JSONConfigScreen(
            title: "服务端高级配置",
            note: "对应 Web 后台的 config.json。保存会整体覆盖服务端配置，请先确认字段无误。",
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
