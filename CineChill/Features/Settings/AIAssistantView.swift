import SwiftUI

/// AI 助手总览：剧集识别模型、上下文策略、记忆、提醒、工具权限。
struct AIAssistantView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    @State private var enabled = false
    @State private var proxyEnabled = false
    @State private var mediaIdentity = true
    @State private var tmdbVerify = true
    @State private var toolsEnabled = false
    @State private var compression = true
    @State private var threshold = 0.5
    @State private var targetRatio = 0.2
    @State private var protectRecent = 20
    @State private var protectHead = 3
    @State private var contextLength = 0
    @State private var baseURL = ""
    @State private var apiKey = ""
    @State private var model = ""
    @State private var testTitle = ""

    var body: some View {
        RemoteList(title: "AI 助手") {
            let api = try session.requireAPI()
            let config = await Probe.json { try await api.ai.readAiEpisodeResolverConfig() }
            let runtime = await Probe.json { try await api.ai.readAiAssistantRuntime() }
            return JSONValue.object(["config": config, "runtime": runtime])
        } content: { value, reload in
            Section("运行状态") {
                KeyValueRow("模型", value["runtime"].deepFirst(of: "model", "current_model"))
                KeyValueRow("可用", value["runtime"].deepFirst(of: "available", "ready", "ok"))
                KeyValueRow("上下文上限", value["runtime"].deepFirst(of: "context_length", "model_context_length"))
                if let message = value["runtime"].deepFirst(of: "message", "error").displayString {
                    Text(message).font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("开关") {
                Toggle("启用 AI 剧集识别", isOn: $enabled)
                Toggle("走系统代理", isOn: $proxyEnabled)
                Toggle("媒体身份识别", isOn: $mediaIdentity)
                Toggle("TMDb 集数校验", isOn: $tmdbVerify)
                Toggle("允许助手调用工具", isOn: $toolsEnabled)
            }

            Section {
                TextField("Base URL", text: $baseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                SecureField("API Key", text: $apiKey)
                TextField("模型名称", text: $model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Stepper("模型上下文 \(contextLength)", value: $contextLength, in: 0...1_000_000, step: 4096)
                Button {
                    runner.run(nil) {
                        let api = try session.requireAPI()
                        return try await api.ai.listAiEpisodeResolverModels(
                            .object(["base_url": .string(baseURL), "api_key": .string(apiKey)]))
                    }
                } label: {
                    Label("拉取可用模型", systemImage: "list.bullet")
                }
                .disabled(baseURL.isEmpty)
                let models = runner.lastResult.list("models", "data", "items")
                if !models.isEmpty {
                    ForEach(Array(models.prefix(60).enumerated()), id: \.offset) { _, item in
                        let name = item.first(of: "id", "name", "model").displayString
                            ?? item.string ?? ""
                        Button {
                            if !name.isEmpty { model = name }
                        } label: {
                            HStack {
                                Text(name).font(.caption)
                                Spacer()
                                if name == model {
                                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("模型接入")
            } footer: {
                Text("兼容 OpenAI 协议的地址即可，例如 https://api.openai.com/v1。API Key 留空表示保留服务器上已有的值。")
            }

            Section("上下文压缩") {
                Toggle("启用压缩", isOn: $compression)
                Stepper("触发阈值 \(String(format: "%.2f", threshold))",
                        value: $threshold, in: 0.1...0.95, step: 0.05)
                Stepper("压缩目标 \(String(format: "%.2f", targetRatio))",
                        value: $targetRatio, in: 0.05...0.8, step: 0.05)
                Stepper("保留最近 \(protectRecent) 条", value: $protectRecent, in: 1...200)
                Stepper("保留开头 \(protectHead) 条", value: $protectHead, in: 0...50)
            }

            Section("识别测试") {
                TextField("文件名或标题", text: $testTitle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    runner.run(nil) {
                        let api = try session.requireAPI()
                        return try await api.ai.testAiEpisodeResolver(
                            .object(["title": .string(testTitle), "filename": .string(testTitle)]))
                    }
                } label: {
                    Label("测试识别", systemImage: "wand.and.stars")
                }
                .disabled(testTitle.isEmpty)
            }

            Section {
                Button {
                    save(reload: reload)
                } label: {
                    Label("保存配置", systemImage: "square.and.arrow.down")
                }
                NavigationLink {
                    AIMemoryView()
                } label: {
                    Label("记忆与人设", systemImage: "brain")
                }
                NavigationLink {
                    AIRemindersView()
                } label: {
                    Label("提醒事项", systemImage: "alarm")
                }
                NavigationLink {
                    AIToolPermissionsView()
                } label: {
                    Label("工具权限", systemImage: "hammer")
                }
                NavigationLink {
                    AIAuditView()
                } label: {
                    Label("调用审计", systemImage: "doc.text.magnifyingglass")
                }
                NavigationLink {
                    AIContextView()
                } label: {
                    Label("当前上下文", systemImage: "text.alignleft")
                }
                JSONInspector(value: value)
            }
            .task { apply(value["config"]) }
        }
        .actionFeedback(runner)
    }

    private func apply(_ config: JSONValue) {
        enabled = config.deepFirst(of: "enabled").bool ?? enabled
        proxyEnabled = config.deepFirst(of: "proxy_enabled").bool ?? proxyEnabled
        mediaIdentity = config.deepFirst(of: "media_identity_enabled").bool ?? mediaIdentity
        tmdbVerify = config.deepFirst(of: "tmdb_episode_verify_enabled").bool ?? tmdbVerify
        toolsEnabled = config.deepFirst(of: "assistant_tools_enabled").bool ?? toolsEnabled
        compression = config.deepFirst(of: "assistant_context_compression_enabled").bool ?? compression
        threshold = config.deepFirst(of: "assistant_context_compression_threshold").double ?? threshold
        targetRatio = config.deepFirst(of: "assistant_context_target_ratio").double ?? targetRatio
        protectRecent = config.deepFirst(of: "assistant_context_protect_recent").int ?? protectRecent
        protectHead = config.deepFirst(of: "assistant_context_protect_head").int ?? protectHead
        contextLength = config.deepFirst(of: "model_context_length").int ?? contextLength
        baseURL = config.deepFirst(of: "base_url").string ?? baseURL
        model = config.deepFirst(of: "model").string ?? model
    }

    private func save(reload: Reload) {
        runner.run("已保存", operation: {
            let api = try session.requireAPI()
            return try await api.ai.updateAiEpisodeResolverConfig(
                AIEpisodeResolverConfigPayload(enabled: enabled,
                                               proxyEnabled: proxyEnabled,
                                               mediaIdentityEnabled: mediaIdentity,
                                               tmdbEpisodeVerifyEnabled: tmdbVerify,
                                               assistantToolsEnabled: toolsEnabled,
                                               assistantContextCompressionEnabled: compression,
                                               assistantContextCompressionThreshold: threshold,
                                               assistantContextTargetRatio: targetRatio,
                                               assistantContextProtectRecent: protectRecent,
                                               assistantContextProtectHead: protectHead,
                                               modelContextLength: contextLength,
                                               baseUrl: baseURL,
                                               apiKey: apiKey,
                                               model: model))
        }, onSuccess: {
            apiKey = ""
            await reload()
        })
    }
}
