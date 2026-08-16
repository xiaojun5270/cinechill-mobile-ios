import SwiftUI

/// Docker 镜像管理：列表、拉取、删除、清理。
struct DockerImagesView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var pullTarget = ""
    @State private var pruneUnused = false
    @State private var pruneUntagged = false
    @State private var deleting: String?

    var body: some View {
        RemoteList(title: "镜像管理") {
            let api = try session.requireAPI()
            return try await api.docker.listImages()
        } content: { value, reload in
            Section("拉取镜像") {
                TextField("镜像名（如 nginx:latest）", text: $pullTarget)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    runner.run("已提交拉取", operation: {
                        let api = try session.requireAPI()
                        return try await api.docker.pullImage(PullImagePayload(image: pullTarget))
                    }, onSuccess: { await reload() })
                } label: {
                    Label("拉取", systemImage: "arrow.down.circle")
                }
                .disabled(pullTarget.isEmpty)
            }

            let images = value.list("images", "items", "data")
            Section("镜像（\(images.count)）") {
                if images.isEmpty { EmptyRow("没有镜像") }
                ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                    imageRow(image)
                }
            }

            Section {
                Button {
                    pruneUntagged = true
                } label: {
                    Label("清理无标签镜像", systemImage: "tag.slash")
                }
                .foregroundStyle(.red)
                Button {
                    pruneUnused = true
                } label: {
                    Label("清理未使用镜像", systemImage: "trash")
                }
                .foregroundStyle(.red)
                JSONInspector(value: value)
            } footer: {
                Text("清理操作会删除服务器上的镜像层，无法撤销。未使用镜像指没有任何容器引用的镜像。")
            }
            .confirmationDialog("清理无标签镜像？", isPresented: $pruneUntagged, titleVisibility: .visible) {
                Button("确认清理", role: .destructive) {
                    runner.run("已清理", operation: {
                        let api = try session.requireAPI()
                        return try await api.docker.pruneUntaggedImages()
                    }, onSuccess: { await reload() })
                }
                Button("取消", role: .cancel) {}
            }
            .confirmationDialog("清理所有未使用镜像？", isPresented: $pruneUnused, titleVisibility: .visible) {
                Button("确认清理", role: .destructive) {
                    runner.run("已清理", operation: {
                        let api = try session.requireAPI()
                        return try await api.docker.pruneUnusedImages()
                    }, onSuccess: { await reload() })
                }
                Button("取消", role: .cancel) {}
            }
            .confirmationDialog("删除该镜像？", isPresented: Binding(get: { deleting != nil },
                                                              set: { if !$0 { deleting = nil } }),
                                titleVisibility: .visible) {
                Button("强制删除", role: .destructive) {
                    let target = deleting ?? ""
                    deleting = nil
                    runner.run("已删除", operation: {
                        let api = try session.requireAPI()
                        return try await api.docker.deleteImage(imageId: target, force: true)
                    }, onSuccess: { await reload() })
                }
                Button("取消", role: .cancel) { deleting = nil }
            }
        }
        .actionFeedback(runner)
    }

    @ViewBuilder
    private func imageRow(_ image: JSONValue) -> some View {
        let id = image.first(of: "id", "Id", "image_id").displayString ?? ""
        VStack(alignment: .leading, spacing: 4) {
            Text(imageName(image))
                .font(.subheadline)
                .lineLimit(2)
            HStack(spacing: 8) {
                if let size = image.first(of: "size", "Size").double {
                    Text(Fmt.bytes(size))
                }
                if let created = image.first(of: "created", "created_at", "Created").displayString {
                    Text("· " + created)
                }
                if image.first(of: "in_use", "used").bool == true {
                    Text("· 使用中")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            if !id.isEmpty {
                Text(id).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                Button("删除") { deleting = id }
                    .font(.caption)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
            }
        }
    }

    private func imageName(_ image: JSONValue) -> String {
        if let tags = image.first(of: "tags", "RepoTags").array, !tags.isEmpty {
            return tags.compactMap { $0.displayString }.joined(separator: ", ")
        }
        return image.first(of: "tag", "name", "repository").displayString ?? "<none>"
    }
}

/// Docker 仓库凭据。
struct DockerRegistryView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()
    @State private var username = ""
    @State private var token = ""
    @State private var confirmDelete = false

    var body: some View {
        RemoteList(title: "仓库凭据") {
            let api = try session.requireAPI()
            return try await api.docker.getRegistryAuth()
        } content: { value, reload in
            Section("当前状态") {
                KeyValueRow("已配置", value.deepFirst(of: "configured", "has_auth", "enabled"))
                KeyValueRow("用户名", value.deepFirst(of: "username", "user"))
            }
            Section("凭据") {
                TextField("用户名", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Token / 密码", text: $token)
                Button {
                    runner.run("已保存", operation: {
                        let api = try session.requireAPI()
                        return try await api.docker.saveRegistryAuth(
                            RegistryAuthPayload(username: username, token: token))
                    }, onSuccess: {
                        token = ""
                        await reload()
                    })
                } label: {
                    Label("保存凭据", systemImage: "square.and.arrow.down")
                }
                .disabled(username.isEmpty || token.isEmpty)
            }
            Section {
                Button {
                    confirmDelete = true
                } label: {
                    Label("删除凭据", systemImage: "trash")
                }
                .foregroundStyle(.red)
                JSONInspector(value: value)
            } footer: {
                Text("Token 仅提交给你自己的 CineChill 服务器，本机不做缓存；服务器不会回传明文。")
            }
            .confirmationDialog("删除仓库凭据？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    runner.run("已删除", operation: {
                        let api = try session.requireAPI()
                        return try await api.docker.deleteRegistryAuth()
                    }, onSuccess: { await reload() })
                }
                Button("取消", role: .cancel) {}
            }
            .task {
                if username.isEmpty {
                    username = value.deepFirst(of: "username", "user").displayString ?? ""
                }
            }
        }
        .actionFeedback(runner)
    }
}
