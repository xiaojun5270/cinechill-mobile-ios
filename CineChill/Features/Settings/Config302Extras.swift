import SwiftUI
import UIKit

/// 单个 Emby 直链配置编辑。
struct Emby302EditorView: View {
    let config: JSONValue
    let index: Int?
    let reload: Reload

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var runner = ActionRunner()
    @State private var draft = Emby302Config()
    @State private var pickcode = true
    @State private var prepared = false
    @State private var confirmDelete = false

    private var isNew: Bool { index == nil }

    var body: some View {
        Form {
            Section("基本") {
                TextField("名称", text: $draft.name)
                TextField("Emby 地址", text: $draft.url)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                SecureField("API Key", text: $draft.key)
                Toggle("启用", isOn: $draft.enabled)
            }
            Section("302 直链") {
                TextField("对外主机（可选）", text: $draft.publicHost)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("代理端口", text: $draft.proxyPort)
                    .textInputAutocapitalization(.never)
                Toggle("pickcode 模式", isOn: $pickcode)
                Toggle("预加载", isOn: $draft.preload)
                Stepper(driveLabel, value: $draft.driveIndex, in: -1...9)
            }
            Section {
                Button(isNew ? "创建 Emby" : "保存修改") { save() }
                    .disabled(draft.url.isEmpty)
                Button("仅保存 Emby 列表") { save(embyOnly: true) }
                    .disabled(draft.url.isEmpty)
                if !isNew {
                    Button("删除此 Emby") { confirmDelete = true }
                        .foregroundStyle(.red)
                }
            } footer: {
                Text("「仅保存 Emby 列表」走 /api/302/emby 接口，不会改动 115 账号配置。网盘序号 -1 表示不绑定具体网盘。")
            }
        }
        .navigationTitle(isNew ? "添加 Emby" : "编辑 Emby")
        .actionFeedback(runner)
        .confirmationDialog("删除该 Emby 配置？", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("删除", role: .destructive) { deleteEmby() }
            Button("取消", role: .cancel) {}
        }
        .task {
            guard !prepared else { return }
            prepared = true
            let payload = Config302View.payload(from: config)
            if let index, index < payload.embys.count {
                draft = payload.embys[index]
                pickcode = draft.modes?.pickcode ?? true
            }
        }
    }

    private var driveLabel: String {
        draft.driveIndex < 0 ? "网盘序号 不绑定" : "网盘序号 \(draft.driveIndex)"
    }

    private func merged() -> Config302Payload {
        var payload = Config302View.payload(from: config)
        var emby = draft
        emby.modes = Emby302Modes(pickcode: pickcode)
        if let index, index < payload.embys.count {
            payload.embys[index] = emby
        } else {
            payload.embys.append(emby)
        }
        return payload
    }

    private func save(embyOnly: Bool = false) {
        runner.run("已保存", operation: {
            let api = try session.requireAPI()
            let payload = merged()
            if embyOnly {
                return try await api.config302.saveEmbyConfig(SaveEmbyPayload(embys: payload.embys))
            }
            return try await api.config302.saveConfig302(payload)
        }, onSuccess: {
            await reload()
            dismiss()
        })
    }

    private func deleteEmby() {
        guard let index else { return }
        runner.run("已删除", operation: {
            let api = try session.requireAPI()
            var payload = Config302View.payload(from: config)
            guard index < payload.embys.count else { return .object(["success": .bool(false)]) }
            payload.embys.remove(at: index)
            return try await api.config302.saveConfig302(payload)
        }, onSuccess: {
            await reload()
            dismiss()
        })
    }
}

/// 115 扫码登录：拉起二维码、轮询状态、把 Cookie 写入指定账号。
struct Qrcode115LoginView: View {
    let config: JSONValue
    let reload: Reload

    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var apps: [String] = ["115android", "115ios", "web", "tv"]
    @State private var app = "115android"
    @State private var uid = ""
    @State private var time = 0
    @State private var sign = ""
    @State private var qrImage: UIImage?
    @State private var qrURL: URL?
    @State private var statusText = "尚未开始"
    @State private var polling = false
    @State private var cookie = ""
    @State private var targetIndex = 0
    @State private var prepared = false

    private var driveCount: Int { Config302View.payload(from: config).drives.count }

    var body: some View {
        Form {
            Section("应用类型") {
                Picker("扫码端", selection: $app) {
                    ForEach(apps, id: \.self) { Text($0).tag($0) }
                }
                Button {
                    start()
                } label: {
                    Label(uid.isEmpty ? "生成二维码" : "重新生成", systemImage: "qrcode")
                }
            }

            Section("二维码") {
                if let qrImage {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                } else if let qrURL {
                    AsyncImage(url: qrURL) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFit()
                        case .failure: Text("二维码加载失败").font(.footnote).foregroundStyle(.red)
                        default: ProgressView()
                        }
                    }
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                } else {
                    EmptyRow("点击上方生成二维码，再用 115 手机客户端扫码")
                }
                HStack {
                    Text("状态").foregroundStyle(.secondary)
                    Spacer()
                    if polling { ProgressView().padding(.trailing, 6) }
                    Text(statusText).font(.footnote)
                }
                Button("刷新状态") { pollOnce() }
                    .disabled(uid.isEmpty)
            }

            if !cookie.isEmpty {
                Section {
                    Text("已获取 Cookie（\(cookie.count) 字符）")
                        .font(.footnote)
                        .foregroundStyle(.green)
                    if driveCount > 0 {
                        Picker("写入账号", selection: $targetIndex) {
                            ForEach(0..<driveCount, id: \.self) { Text("网盘 #\($0)").tag($0) }
                        }
                    } else {
                        Text("当前没有 115 账号，将新建一个").font(.caption).foregroundStyle(.secondary)
                    }
                    Button {
                        applyCookie()
                    } label: {
                        Label("保存到配置", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("登录结果")
                } footer: {
                    Text("Cookie 只会提交给你自己的 CineChill 服务器，本机不做持久化。")
                }
            }
        }
        .navigationTitle("115 扫码登录")
        .actionFeedback(runner)
        .task {
            guard !prepared else { return }
            prepared = true
            await loadApps()
        }
    }

    private func loadApps() async {
        guard let api = session.api else { return }
        let value = await Probe.json { try await api.config302.get115QrcodeApps() }
        let list = value.list("apps", "items", "data")
        let names = list.compactMap { $0.first(of: "app", "key", "name", "value").displayString ?? $0.string }
        if !names.isEmpty {
            apps = names
            if !names.contains(app) { app = names[0] }
        }
    }

    private func start() {
        runner.run(nil, operation: {
            let api = try session.requireAPI()
            return try await api.config302.start115Qrcode(Start115QrPayload(app: app))
        }, onSuccess: {
            let result = runner.lastResult
            uid = result.deepFirst(of: "uid").displayString ?? ""
            time = result.deepFirst(of: "time").int ?? 0
            sign = result.deepFirst(of: "sign").displayString ?? ""
            cookie = ""
            qrImage = nil
            qrURL = nil
            applyQRImage(result)
            statusText = uid.isEmpty ? "未取得二维码参数" : "等待扫码"
            if !uid.isEmpty { await pollLoop() }
        })
    }

    private func applyQRImage(_ result: JSONValue) {
        if let raw = result.deepFirst(of: "qrcode", "qr_code", "image", "qrcode_base64").string {
            if raw.hasPrefix("http"), let url = URL(string: raw) {
                qrURL = url
                return
            }
            let cleaned = raw.contains(",") ? String(raw.split(separator: ",").last ?? "") : raw
            if let data = Data(base64Encoded: cleaned), let image = UIImage(data: data) {
                qrImage = image
                return
            }
        }
        if let link = result.deepFirst(of: "qrcode_url", "url", "image_url").string {
            qrURL = session.absoluteURL(link)
        }
    }

    private func pollOnce() {
        Task { await poll() }
    }

    private func pollLoop() async {
        polling = true
        for _ in 0..<60 {
            if cookie.isEmpty == false { break }
            let done = await poll()
            if done { break }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        polling = false
    }

    /// 返回 true 表示不需要继续轮询。
    @discardableResult
    private func poll() async -> Bool {
        guard let api = session.api, !uid.isEmpty else { return true }
        let status = await Probe.json {
            try await api.config302.get115QrcodeStatus(Status115QrPayload(uid: uid, time: time, sign: sign))
        }
        let code = status.deepFirst(of: "status", "state", "code")
        let text = code.displayString ?? "—"
        statusText = describe(text)
        if let message = status.deepFirst(of: "message", "msg").displayString, code.isNull {
            statusText = message
        }
        if text == "2" || text.lowercased() == "confirmed" || text.lowercased() == "success" {
            await fetchResult()
            return true
        }
        if text == "-2" || text.lowercased() == "expired" || text.lowercased() == "canceled" {
            return true
        }
        return false
    }

    private func describe(_ code: String) -> String {
        switch code {
        case "0": return "等待扫码"
        case "1": return "已扫码，等待确认"
        case "2": return "已确认"
        case "-1": return "二维码已失效"
        case "-2": return "已取消"
        default: return code
        }
    }

    private func fetchResult() async {
        guard let api = session.api else { return }
        let result = await Probe.json {
            try await api.config302.get115QrcodeResult(Result115QrPayload(uid: uid, app: app))
        }
        if let value = result.deepFirst(of: "cookie", "cookies").displayString, !value.isEmpty {
            cookie = value
            statusText = "登录成功"
        } else {
            statusText = result.errorMessage ?? "已确认，但未取得 Cookie"
        }
    }

    private func applyCookie() {
        runner.run("已写入配置", operation: {
            let api = try session.requireAPI()
            var payload = Config302View.payload(from: config)
            if targetIndex < payload.drives.count {
                payload.drives[targetIndex].cookie = cookie
            } else {
                payload.drives.append(Drive115Config(cookie: cookie))
            }
            return try await api.config302.saveConfig302(payload)
        }, onSuccess: {
            cookie = ""
            await reload()
        })
    }
}

/// 单独测试一段 115 Cookie。
struct Cookie115TestView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var cookie = ""

    var body: some View {
        Form {
            Section {
                SecureField("115 Cookie", text: $cookie)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    runner.run("Cookie 可用") {
                        let api = try session.requireAPI()
                        return try await api.config302.test115Cookie(Test115Payload(cookie: cookie))
                    }
                } label: {
                    Label("测试", systemImage: "bolt.horizontal")
                }
                .disabled(cookie.isEmpty)
            } footer: {
                Text("仅用于校验，不会写入服务器配置。")
            }
            if runner.lastResult.isNull == false {
                Section("返回") { JSONFieldList(value: runner.lastResult) }
            }
        }
        .navigationTitle("测试 Cookie")
        .actionFeedback(runner)
    }
}

/// 创建标准目录结构。
struct StandardTopologyView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var localRoot = ""
    @State private var remoteRoot = "影视库"

    var body: some View {
        Form {
            Section {
                TextField("本地媒体根目录", text: $localRoot)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("网盘根目录名", text: $remoteRoot)
                Button {
                    runner.run("已创建目录") {
                        let api = try session.requireAPI()
                        return try await api.config302.ensureStandardTopologyDirs(
                            StandardTopologyDirsPayload(localMediaRoot: localRoot,
                                                        remoteRootName: remoteRoot))
                    }
                } label: {
                    Label("创建目录结构", systemImage: "folder.badge.plus")
                }
                .disabled(localRoot.isEmpty)
            } footer: {
                Text("会在本地根目录与 115 根目录下按电影 / 剧集 / 动漫等标准分类建立子目录，已存在的目录不会被改动。")
            }
            if runner.lastResult.isNull == false {
                Section("返回") { JSONFieldList(value: runner.lastResult) }
            }
        }
        .navigationTitle("标准目录结构")
        .actionFeedback(runner)
    }
}

/// 302 原始配置编辑。
struct Config302RawView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        JSONConfigScreen(
            title: "302 原始配置",
            note: "drives 为 115 账号数组，embys 为 Emby 直链数组。保存会整体覆盖服务端 302 配置。",
            unwrapKeys: ["config", "data"],
            load: {
                let api = try session.requireAPI()
                return try await api.config302.getConfig302()
            },
            save: { edited in
                let api = try session.requireAPI()
                return try await api.config302.saveConfig302(try edited.decoded(Config302Payload.self))
            })
    }
}
