import SwiftUI

/// 二级分类规则：查看/编辑当前规则，并与服务端默认规则对比。
struct CategoryRulesView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var runner = ActionRunner()

    @State private var draft: JSONValue = .null
    @State private var phase: Phase = .loading

    private enum Phase: Equatable { case loading, ready, failed(String) }

    var body: some View {
        Form {
            switch phase {
            case .loading:
                LoadingRow()
            case .failed(let message):
                FailureRow(message: message) { Task { await reload() } }
            case .ready:
                Section {
                    Text("规则按顺序匹配，命中即停止。常见字段：name（分类名）、genre_ids / genres（题材）、original_language（原始语言）、production_countries（地区）。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("电影分类") {
                    NavigationLink {
                        JSONArrayEditorScreen(title: "电影分类", value: $draft.child("movie"))
                    } label: {
                        ruleRow("电影", count: draft["movie"].array?.count ?? 0)
                    }
                }
                Section("剧集分类") {
                    NavigationLink {
                        JSONArrayEditorScreen(title: "剧集分类", value: $draft.child("tv"))
                    } label: {
                        ruleRow("剧集", count: draft["tv"].array?.count ?? 0)
                    }
                }
                Section {
                    Button {
                        save()
                    } label: {
                        Label("保存规则", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        Task { await loadDefaults() }
                    } label: {
                        Label("载入默认规则（不自动保存）", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
        .navigationTitle("二级分类规则")
        .actionFeedback(runner)
        .task { if phase == .loading { await reload() } }
    }

    private func ruleRow(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(count) 条规则").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func save() {
        runner.run("规则已保存") {
            let api = try session.requireAPI()
            return try await api.organize.saveCategoryRules(
                CategoryRulesPayload(movie: draft["movie"].array ?? [],
                                     tv: draft["tv"].array ?? []))
        }
    }

    private func loadDefaults() async {
        guard let api = session.api else { return }
        let defaults = await Probe.json { try await api.organize.getDefaultCategoryRules() }
        let normalized = normalize(defaults)
        if !normalized.isEmptyContainer { draft = normalized }
    }

    private func reload() async {
        do {
            let api = try session.requireAPI()
            draft = normalize(try await api.organize.getCategoryRules())
            phase = .ready
        } catch let error as APIError {
            if error.isAuthFailure { session.handle(error: error) }
            phase = .failed(error.errorDescription ?? "加载失败")
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    /// 服务端可能返回 `{movie:[],tv:[]}` 或包一层 `{rules:{...}}` / `{data:{...}}`。
    private func normalize(_ value: JSONValue) -> JSONValue {
        var node = value
        for key in ["rules", "data", "config", "categories"] where node[key].object != nil {
            node = node[key]
            break
        }
        let movie = node.deepFirst(of: "movie", "movies", "电影").array ?? []
        let tv = node.deepFirst(of: "tv", "series", "电视剧").array ?? []
        return .object(["movie": .array(movie), "tv": .array(tv)])
    }
}
