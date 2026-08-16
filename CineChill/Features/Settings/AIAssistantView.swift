import SwiftUI

/// AI 助手总览：模型接入、自动策略、上下文策略和运行统计。
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
    @State private var detectedContextLength = 128_000
    @State private var baseURL = "https://api.openai.com/v1"
    @State private var apiKey = ""
    @State private var model = ""
    @State private var systemProxyURL = ""
    @State private var models: [JSONValue] = []
    @State private var connectionResult: JSONValue = .null

    var body: some View {
        RemoteList(title: "AI 助手") {
            let api = try session.requireAPI()
            let config = Self.unwrap(try await api.ai.readAiEpisodeResolverConfig())
            async let runtimeTask = Probe.json { try await api.ai.readAiAssistantRuntime() }
            async let permissionsTask = Probe.json { try await api.ai.readAiAssistantToolPermissions() }
            let runtime = await runtimeTask
            let permissions = await permissionsTask

            return .object([
                "config": config,
                "runtime": runtime,
                "permissions": permissions,
            ])
        } content: { value, reload in
            let runtime = value["runtime"]
            let permissions = value["permissions"]["tools"].object ?? [:]
            let enabledToolCount = permissions.values.filter { $0["enabled"].bool == true }.count

            Section("运行状态") {
                KeyValueRow("AI 助手", assistantStatus)
                KeyValueRow("模型", model.isEmpty ? "未选择" : model)
                KeyValueRow("模型连接", connectionStatus)
                if let latency = connectionResult["latency_ms"].displayString {
                    KeyValueRow("连接延迟", "\(latency) ms")
                }
                KeyValueRow("上下文预算", Self.tokenText(effectiveContextLength))
                if runtime.isNull {
                    Text("运行统计暂未获取")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    let memory = runtime["memory"]
                    let memoryCount = (memory["memory_count"].int ?? 0)
                        + (memory["global_profile_count"].int ?? 0)
                    KeyValueRow("长期记忆", "\(memoryCount) 条")
                    KeyValueRow("上下文会话", "\(runtime["context"]["conversation_count"].int ?? 0) 个")
                    KeyValueRow("待执行提醒", "\(runtime["reminders"]["scheduled_count"].int ?? 0) 个")
                }
                if value["permissions"].isNull == false {
                    KeyValueRow("工具权限", "\(enabledToolCount)/\(permissions.count) 已启用")
                }
            }

            Section("开关") {
                Toggle("启用 AI 助手", isOn: $enabled)
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
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if models.isEmpty {
                    TextField("模型名称", text: $model)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    Picker("模型", selection: $model) {
                        Text("请选择模型").tag("")
                        ForEach(modelIDs, id: \.self) { id in
                            Text(modelLabel(id)).tag(id)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: model) { _, selected in
                        applyContextLength(for: selected)
                    }
                }

                Stepper("模型上下文：\(Self.tokenText(contextLength))",
                        value: $contextLength, in: 0...2_000_000, step: 1_024)
                KeyValueRow("当前上下文预算", Self.tokenText(effectiveContextLength))
                if proxyEnabled {
                    KeyValueRow("统一代理地址", systemProxyURL.isEmpty ? "工具箱未配置" : systemProxyURL,
                                monospaced: true)
                }

                Button {
                    loadModels()
                } label: {
                    Label("获取模型列表", systemImage: "list.bullet")
                }
                .disabled(baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    testConnection()
                } label: {
                    Label("测试模型连接", systemImage: "bolt.horizontal.circle")
                }
                .disabled(!configurationReady)

                if connectionResult.isNull == false {
                    KeyValueRow("测试结果", connectionResult["ok"].bool == true ? "连接成功" : "连接失败")
                    if let message = connectionResult["message"].displayString, !message.isEmpty {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("模型接入")
            } footer: {
                Text("兼容 OpenAI Chat Completions 格式。模型列表和连接测试使用当前页面的完整配置。")
            }

            Section("上下文压缩") {
                Toggle("启用压缩", isOn: $compression)
                Stepper("触发阈值 \(String(format: "%.2f", threshold))",
                        value: $threshold, in: 0.1...0.95, step: 0.05)
                Stepper("压缩目标 \(String(format: "%.2f", targetRatio))",
                        value: $targetRatio, in: 0.1...0.8, step: 0.05)
                Stepper("保护最近 \(protectRecent) 条", value: $protectRecent, in: 4...80)
                Stepper("保护开头 \(protectHead) 条", value: $protectHead, in: 0...20)
                let triggerTokens = Int(Double(effectiveContextLength) * threshold)
                KeyValueRow("预计压缩触发", Self.tokenText(triggerTokens))
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
            }
            .task(id: value) {
                apply(value["config"])
                connectionResult = .null
                if configurationReady {
                    await testConnectionSilently()
                }
            }
        }
        .actionFeedback(runner)
    }

    private var configurationReady: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var effectiveContextLength: Int {
        contextLength > 0 ? contextLength : detectedContextLength
    }

    private var assistantStatus: String {
        guard enabled else { return "已关闭" }
        return configurationReady ? "运行中" : "待补全配置"
    }

    private var connectionStatus: String {
        guard configurationReady else { return "待配置" }
        guard connectionResult.isNull == false else { return "待检测" }
        return connectionResult["ok"].bool == true ? "连接成功" : "连接失败"
    }

    private var modelIDs: [String] {
        var ids = models.compactMap { item in
            item.first(of: "id", "name", "model").displayString ?? item.string
        }.filter { !$0.isEmpty }
        if !model.isEmpty, !ids.contains(model) { ids.insert(model, at: 0) }
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }

    private func modelLabel(_ id: String) -> String {
        guard let item = models.first(where: {
            ($0.first(of: "id", "name", "model").displayString ?? $0.string) == id
        }) else { return "\(id)（当前）" }
        let owner = item["owned_by"].displayString
        let context = item["context_length"].int.map(Self.tokenText)
        return [id, owner, context].compactMap { $0 }.joined(separator: " / ")
    }

    private func applyContextLength(for selected: String) {
        guard let item = models.first(where: {
            ($0.first(of: "id", "name", "model").displayString ?? $0.string) == selected
        }), let length = item["context_length"].int else { return }
        contextLength = length
    }

    private func apply(_ config: JSONValue) {
        let payload = Self.payload(from: config)
        enabled = payload.enabled
        proxyEnabled = payload.proxyEnabled
        mediaIdentity = payload.mediaIdentityEnabled
        tmdbVerify = payload.tmdbEpisodeVerifyEnabled
        toolsEnabled = payload.assistantToolsEnabled
        compression = payload.assistantContextCompressionEnabled
        threshold = payload.assistantContextCompressionThreshold
        targetRatio = payload.assistantContextTargetRatio
        protectRecent = payload.assistantContextProtectRecent
        protectHead = payload.assistantContextProtectHead
        contextLength = payload.modelContextLength
        baseURL = payload.baseUrl
        apiKey = payload.apiKey
        model = payload.model
        detectedContextLength = config["detected_context_length"].int ?? 128_000
        systemProxyURL = config["proxy_url"].string ?? ""
    }

    private func loadModels() {
        runner.run("模型列表已更新", operation: {
            let api = try session.requireAPI()
            return try await api.ai.listAiEpisodeResolverModels(.encoding(currentPayload()))
        }, onSuccess: {
            let response = runner.lastResult
            models = response["models"].array ?? response.list("models", "data", "items")
            if model.isEmpty, let first = models.first,
               let firstID = first.first(of: "id", "name", "model").displayString ?? first.string {
                model = firstID
                applyContextLength(for: firstID)
            } else if let selectedLength = response["selected_context_length"].int,
                      selectedLength > 0 {
                contextLength = selectedLength
            }
        })
    }

    private func testConnection() {
        connectionResult = .null
        runner.run("模型连接测试完成", operation: {
            let api = try session.requireAPI()
            let result = try await api.ai.testAiEpisodeResolver(.encoding(currentPayload()))
            connectionResult = result
            return result
        })
    }

    @MainActor
    private func testConnectionSilently() async {
        do {
            let api = try session.requireAPI()
            connectionResult = try await api.ai.testAiEpisodeResolver(.encoding(currentPayload()))
        } catch {
            connectionResult = .object([
                "ok": .bool(false),
                "message": .string((error as? LocalizedError)?.errorDescription
                                   ?? error.localizedDescription),
            ])
        }
    }

    private func save(reload: Reload) {
        runner.run("AI 助手配置已保存", operation: {
            let api = try session.requireAPI()
            return try await api.ai.updateAiEpisodeResolverConfig(currentPayload())
        }, onSuccess: {
            await reload()
        })
    }

    private func currentPayload() -> AIEpisodeResolverConfigPayload {
        AIEpisodeResolverConfigPayload(
            enabled: enabled,
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
            model: model)
    }

    private static func payload(from config: JSONValue) -> AIEpisodeResolverConfigPayload {
        AIEpisodeResolverConfigPayload(
            enabled: config["enabled"].bool ?? false,
            proxyEnabled: config["proxy_enabled"].bool ?? false,
            mediaIdentityEnabled: config["media_identity_enabled"].bool ?? true,
            tmdbEpisodeVerifyEnabled: config["tmdb_episode_verify_enabled"].bool ?? true,
            assistantToolsEnabled: config["assistant_tools_enabled"].bool ?? false,
            assistantContextCompressionEnabled: config["assistant_context_compression_enabled"].bool ?? true,
            assistantContextCompressionThreshold: min(max(config["assistant_context_compression_threshold"].double ?? 0.5, 0.1), 0.95),
            assistantContextTargetRatio: min(max(config["assistant_context_target_ratio"].double ?? 0.2, 0.1), 0.8),
            assistantContextProtectRecent: min(max(config["assistant_context_protect_recent"].int ?? 20, 4), 80),
            assistantContextProtectHead: min(max(config["assistant_context_protect_head"].int ?? 3, 0), 20),
            modelContextLength: min(max(config["model_context_length"].int ?? 0, 0), 2_000_000),
            baseUrl: config["base_url"].string ?? "https://api.openai.com/v1",
            apiKey: config["api_key"].string ?? "",
            model: config["model"].string ?? "")
    }

    private static func unwrap(_ value: JSONValue) -> JSONValue {
        for key in ["config", "data", "settings"] where value[key].object != nil {
            return value[key]
        }
        return value
    }

    private static func tokenText(_ count: Int) -> String {
        guard count > 0 else { return "自动识别" }
        if count >= 1_000_000 {
            let value = Double(count) / 1_000_000
            return value == value.rounded() ? "\(Int(value))M tokens" : String(format: "%.2fM tokens", value)
        }
        if count >= 1_000 { return "\(Int((Double(count) / 1_000).rounded()))K tokens" }
        return "\(count) tokens"
    }
}
