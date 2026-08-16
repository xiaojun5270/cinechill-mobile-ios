import SwiftUI

/// 根视图：按会话状态在「配置服务器 / 登录 / 主界面」之间切换。
struct RootView: View {
    @EnvironmentObject private var session: AppSession
    @State private var didRestore = false

    var body: some View {
        Group {
            switch session.authState {
            case .needsServer:
                NavigationStack {
                    ServerEditorView(profile: ServerProfile(), isFirstRun: true)
                }
            case .loggedOut, .authenticating:
                NavigationStack {
                    LoginView()
                }
            case .loggedIn:
                MainTabView()
            }
        }
        .task {
            guard !didRestore else { return }
            didRestore = true
            if session.activeServer != nil {
                await session.restoreSession()
            }
        }
    }
}

/// 登录页：选择服务器 + 账号密码。
struct LoginView: View {
    @EnvironmentObject private var session: AppSession
    @State private var username = ""
    @State private var password = ""
    @State private var remember = true
    @State private var isWorking = false
    @State private var errorText: String?
    @FocusState private var focus: Field?

    private enum Field: Hashable { case username, password }

    var body: some View {
        Form {
            Section {
                if session.servers.isEmpty {
                    Text("尚未配置服务器").foregroundStyle(.secondary)
                } else {
                    Picker("服务器", selection: Binding(
                        get: { session.activeServerID ?? session.servers.first?.id },
                        set: { if let id = $0 { session.select(id); syncFromProfile() } })) {
                        ForEach(session.servers) { profile in
                            Text(profile.displayName).tag(Optional(profile.id))
                        }
                    }
                }
                if let profile = session.activeServer {
                    KeyValueRow("地址", profile.baseURLString, monospaced: true)
                }
                NavigationLink {
                    ServerListView()
                } label: {
                    Label("管理服务器", systemImage: "server.rack")
                }
            } header: {
                Text("连接")
            }

            Section {
                TextField("用户名", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .focused($focus, equals: .username)
                    .submitLabel(.next)
                    .onSubmit { focus = .password }
                SecureField("密码", text: $password)
                    .textContentType(.password)
                    .focused($focus, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { submit() }
                Toggle("记住密码（存入钥匙串）", isOn: $remember)
            } header: {
                Text("账号")
            } footer: {
                Text("密码仅保存在本机钥匙串中，用于自动重连。")
            }

            Section {
                Button {
                    submit()
                } label: {
                    HStack {
                        if isWorking { ProgressView().padding(.trailing, 6) }
                        Text(isWorking ? "登录中…" : "登录")
                    }
                }
                .disabled(isWorking || session.activeServer == nil || username.isEmpty)
            }

            if let errorText {
                Section {
                    Label(errorText, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("CineChill")
        .onAppear { syncFromProfile() }
    }

    private func syncFromProfile() {
        guard let profile = session.activeServer else { return }
        username = profile.username
        remember = profile.rememberPassword
        if profile.rememberPassword, let saved = session.savedPassword(for: profile) {
            password = saved
        } else {
            password = ""
        }
    }

    private func submit() {
        guard var profile = session.activeServer, !isWorking else { return }
        errorText = nil
        isWorking = true
        profile.rememberPassword = remember
        profile.username = username
        session.upsert(profile, password: remember ? password : nil)
        Task {
            do {
                try await session.login(username: username, password: password)
            } catch {
                errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isWorking = false
        }
    }
}

/// 服务器列表：新增、切换、编辑、删除。
struct ServerListView: View {
    @EnvironmentObject private var session: AppSession
    @State private var editing: ServerProfile?
    @State private var creating = false

    var body: some View {
        List {
            Section {
                ForEach(session.servers) { profile in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.displayName)
                                .foregroundStyle(.primary)
                            Text(profile.baseURLString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if profile.id == session.activeServerID {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { session.select(profile.id) }
                    .swipeActions(edge: .leading) {
                        Button {
                            editing = profile
                        } label: {
                            Label("编辑", systemImage: "slider.horizontal.3")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        if index < session.servers.count {
                            session.remove(session.servers[index])
                        }
                    }
                }
            } header: {
                Text("已保存的服务器")
            } footer: {
                Text("切换服务器后需要重新登录。")
            }

            Section {
                Button {
                    creating = true
                } label: {
                    Label("添加服务器", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("服务器")
        .toolbar { EditButton() }
        .sheet(item: $editing) { profile in
            NavigationStack {
                ServerEditorView(profile: profile, isFirstRun: false)
            }
        }
        .sheet(isPresented: $creating) {
            NavigationStack {
                ServerEditorView(profile: ServerProfile(), isFirstRun: false)
            }
        }
    }
}

/// 服务器编辑：地址解析 + 连通性测试。
struct ServerEditorView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var address: String
    @State private var username: String
    @State private var password: String
    @State private var remember: Bool
    @State private var allowInsecureTLS: Bool
    @State private var testResult: String?
    @State private var testFailed = false
    @State private var isTesting = false

    private let original: ServerProfile
    private let isFirstRun: Bool

    init(profile: ServerProfile, isFirstRun: Bool) {
        self.original = profile
        self.isFirstRun = isFirstRun
        _name = State(initialValue: profile.name)
        _address = State(initialValue: profile.host.isEmpty ? "" : profile.baseURLString)
        _username = State(initialValue: profile.username)
        _password = State(initialValue: Keychain.read(account: profile.passwordAccount) ?? "")
        _remember = State(initialValue: profile.rememberPassword)
        _allowInsecureTLS = State(initialValue: profile.allowInsecureTLS)
    }

    private var parsed: (scheme: String, host: String, port: Int)? {
        ServerProfile.parse(address: address)
    }

    private var draft: ServerProfile? {
        guard let parsed else { return nil }
        var profile = original
        profile.name = name.trimmingCharacters(in: .whitespaces)
        profile.scheme = parsed.scheme
        profile.host = parsed.host
        profile.port = parsed.port
        profile.username = username.trimmingCharacters(in: .whitespaces)
        profile.rememberPassword = remember
        profile.allowInsecureTLS = allowInsecureTLS
        return profile.isValid ? profile : nil
    }

    var body: some View {
        Form {
            Section {
                TextField("备注名称（可选）", text: $name)
                TextField("服务器地址", text: $address)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                if let parsed {
                    KeyValueRow("将连接", "\(parsed.scheme)://\(parsed.host):\(parsed.port)", monospaced: true)
                } else if !address.isEmpty {
                    Text("地址无法解析").font(.footnote).foregroundStyle(.red)
                }
            } header: {
                Text("服务器")
            } footer: {
                Text("支持 192.168.1.10:5256、http://nas.local:5256、https://domain 等写法；未写端口时 http 默认 5256。")
            }

            Section {
                TextField("用户名", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("密码", text: $password)
                Toggle("记住密码（钥匙串）", isOn: $remember)
            } header: {
                Text("账号")
            }

            Section {
                Toggle("允许自签名 HTTPS 证书", isOn: $allowInsecureTLS)
            } footer: {
                Text("仅在自建 HTTPS 且证书不受信任时开启。开启后本 App 对该主机不校验证书，存在被中间人攻击的风险；局域网 http 访问不需要开启。")
            }

            Section {
                Button {
                    test()
                } label: {
                    HStack {
                        if isTesting { ProgressView().padding(.trailing, 6) }
                        Text("测试连接")
                    }
                }
                .disabled(draft == nil || isTesting)
                if let testResult {
                    Label(testResult, systemImage: testFailed ? "xmark.circle" : "checkmark.circle")
                        .font(.footnote)
                        .foregroundStyle(testFailed ? .red : .green)
                }
            }
        }
        .navigationTitle(original.host.isEmpty ? "添加服务器" : "编辑服务器")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") { save() }
                    .disabled(draft == nil)
            }
            if !isFirstRun {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private func save() {
        guard let draft else { return }
        session.upsert(draft, password: remember ? password : nil)
        session.select(draft.id)
        if !isFirstRun { dismiss() }
    }

    private func test() {
        guard let draft, let url = draft.baseURL else { return }
        isTesting = true
        testResult = nil
        Task {
            let probe = APIClient(baseURL: url, serverID: draft.id,
                                  allowInsecureTLS: draft.allowInsecureTLS)
            do {
                let version = try await CineChillAPI(client: probe).meta.apiVersion()
                testFailed = false
                let text = version.first(of: "version", "api_version").displayString
                testResult = "连接成功" + (text.map { "，服务端版本 \($0)" } ?? "")
            } catch let error as APIError {
                if error.isAuthFailure {
                    testFailed = false
                    testResult = "连接成功（需要登录）"
                } else {
                    testFailed = true
                    testResult = error.errorDescription ?? "连接失败"
                }
            } catch {
                testFailed = true
                testResult = error.localizedDescription
            }
            isTesting = false
        }
    }
}
