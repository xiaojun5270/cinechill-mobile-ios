import SwiftUI
import UIKit

/// 全局功能搜索：129 个页面原本要在五个标签页里逐层点开，这里一次搜到底。
struct ModuleSearchView: View {
    @EnvironmentObject private var favorites: ModuleFavorites
    @State private var query = ""

    private var results: [ModuleEntry] {
        ModuleIndex.all.filter { $0.matches(query) }
    }

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        List {
            if isSearching {
                Section {
                    ForEach(results) { entry in
                        ModuleLink(entry: entry, showGroup: true)
                    }
                } header: {
                    Text("\(results.count) 个结果")
                }
            } else {
                if !favorites.favorites.isEmpty {
                    Section("收藏") {
                        ForEach(favorites.favorites) { entry in
                            ModuleLink(entry: entry, showGroup: true)
                        }
                    }
                }
                if !favorites.recents.isEmpty {
                    Section {
                        ForEach(favorites.recents) { entry in
                            ModuleLink(entry: entry, showGroup: true)
                        }
                        Button {
                            favorites.clearRecents()
                        } label: {
                            Label("清空最近访问", systemImage: "eraser")
                                .font(.footnote)
                        }
                    } header: {
                        Text("最近访问")
                    }
                }
                ForEach(AppTab.allCases) { tab in
                    Section {
                        ForEach(ModuleIndex.items(for: tab)) { entry in
                            ModuleLink(entry: entry, showGroup: true)
                        }
                    } header: {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "搜索页面、接口路径或关键词")
        .overlay {
            if isSearching && results.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .navigationTitle("全部功能")
        .glassNavigationBar()
    }
}

/// 索引里的一行：点进去记一次访问，左滑或长按可收藏。
struct ModuleLink: View {
    let entry: ModuleEntry
    var showGroup = false

    @EnvironmentObject private var favorites: ModuleFavorites

    private var isFavorite: Bool { favorites.isFavorite(entry.id) }

    var body: some View {
        NavigationLink {
            entry.destination()
                .onAppear { favorites.noteVisit(entry.id) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: entry.systemImage)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(entry.tint.gradient, in: RoundedRectangle(cornerRadius: 7))
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                    if showGroup {
                        Text("\(entry.tab.title) · \(entry.group)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 4)
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                favorites.toggle(entry.id)
            } label: {
                Label(isFavorite ? "取消收藏" : "收藏",
                      systemImage: isFavorite ? "star.slash" : "star")
            }
            .tint(.yellow)
        }
        .contextMenu {
            Button {
                favorites.toggle(entry.id)
            } label: {
                Label(isFavorite ? "取消收藏" : "加入收藏",
                      systemImage: isFavorite ? "star.slash" : "star")
            }
        }
    }
}

/// 仪表盘上的「常用」卡片：收藏在前，最近访问补位。
struct FavoriteModulesCard: View {
    @EnvironmentObject private var favorites: ModuleFavorites

    private var entries: [ModuleEntry] {
        let picked = favorites.favorites + favorites.recents
        return Array(picked.prefix(8))
    }

    var body: some View {
        CardSection(title: "常用", systemImage: "star",
                    trailing: AnyView(
                        NavigationLink {
                            ModuleSearchView()
                        } label: {
                            Text("全部功能").font(.caption)
                        }
                    )) {
            if entries.isEmpty {
                Text("在「全部功能」里左滑任意页面即可收藏，最近访问过的页面也会出现在这里。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(entries) { entry in
                        NavigationLink {
                            entry.destination()
                                .onAppear { favorites.noteVisit(entry.id) }
                        } label: {
                            ShortcutTile(entry: entry,
                                         isFavorite: favorites.isFavorite(entry.id))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                favorites.toggle(entry.id)
                            } label: {
                                Label(favorites.isFavorite(entry.id) ? "取消收藏" : "加入收藏",
                                      systemImage: favorites.isFavorite(entry.id) ? "star.slash" : "star")
                            }
                        }
                    }
                }
            }
        }
    }
}

/// 常用卡片里的小方块。
struct ShortcutTile: View {
    let entry: ModuleEntry
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.systemImage)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(entry.tint.gradient, in: RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(entry.group)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .tertiarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 10))
    }
}
