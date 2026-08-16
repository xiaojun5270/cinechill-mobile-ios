import SwiftUI

/// 115 目录浏览器：逐层进入目录并选择一个目录返回。
struct Drive115BrowserView: View {
    let onPick: (CleanupFolderDraft) -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    struct Crumb: Hashable {
        var cid: String
        var name: String
    }

    @State private var stack: [Crumb] = [Crumb(cid: "0", name: "根目录")]
    @State private var items: [JSONValue] = []
    @State private var loading = false
    @State private var failure: String?

    private var current: Crumb { stack.last ?? Crumb(cid: "0", name: "根目录") }

    private var currentPath: String {
        "/" + stack.dropFirst().map(\.name).joined(separator: "/")
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text(currentPath == "/" ? "/" : currentPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer()
                    if stack.count > 1 {
                        Button("上一级") { stack.removeLast() }
                            .font(.caption)
                            .buttonStyle(.borderless)
                    }
                }
                Button {
                    onPick(CleanupFolderDraft(cid: current.cid, name: current.name, path: currentPath))
                    dismiss()
                } label: {
                    Label("选择当前目录", systemImage: "checkmark.circle")
                }
            }

            if loading {
                LoadingRow()
            } else if let failure {
                Section {
                    Text(failure).font(.footnote).foregroundStyle(.red)
                    Button("重试") { Task { await load() } }
                }
            } else {
                Section("子目录（\(items.count)）") {
                    if items.isEmpty { EmptyRow("没有子目录") }
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        folderRow(item)
                    }
                }
            }
        }
        .navigationTitle("选择 115 目录")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
        }
        .task(id: current.cid) { await load() }
    }

    @ViewBuilder
    private func folderRow(_ item: JSONValue) -> some View {
        let cid = item.first(of: "cid", "id", "file_id").displayString ?? ""
        let name = item.first(of: "name", "file_name", "n").displayString ?? "—"
        HStack {
            Image(systemName: "folder")
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline).lineLimit(1)
                if !cid.isEmpty {
                    Text("CID \(cid)").font(.caption2).foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Button {
                onPick(CleanupFolderDraft(cid: cid, name: name,
                                          path: (currentPath == "/" ? "" : currentPath) + "/" + name))
                dismiss()
            } label: {
                Text("选择").font(.caption)
            }
            .buttonStyle(.borderless)
            .disabled(cid.isEmpty)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !cid.isEmpty else { return }
            stack.append(Crumb(cid: cid, name: name))
        }
    }

    private func load() async {
        guard let api = session.api else {
            failure = "请先登录服务器"
            return
        }
        loading = true
        failure = nil
        do {
            let value = try await api.cleanup115.browse115(Browse115Payload(cid: current.cid))
            let list = value.list("folders", "items", "data", "list")
            items = list.filter { entry in
                // 目录条目通常没有 fid/sha，或带有 is_dir 标记。
                if let isDir = entry.first(of: "is_dir", "isDir", "folder").bool { return isDir }
                return entry.first(of: "cid", "id", "file_id").isNull == false
            }
            if items.isEmpty { items = list }
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            if case .cancelled = error {
                loading = false
                return
            }
            failure = error.errorDescription ?? "读取失败"
        } catch {
            failure = error.localizedDescription
        }
        loading = false
    }
}
