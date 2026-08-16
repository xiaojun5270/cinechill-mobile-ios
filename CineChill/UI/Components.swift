import SwiftUI
import UIKit

// MARK: - 文本与状态

/// 键值行，右侧值可选择长按复制。
public struct KeyValueRow: View {
    let label: String
    let value: String
    var monospaced: Bool = false

    public init(_ label: String, _ value: String, monospaced: Bool = false) {
        self.label = label
        self.value = value
        self.monospaced = monospaced
    }

    public init(_ label: String, _ value: JSONValue, monospaced: Bool = false) {
        self.init(label, Fmt.text(value), monospaced: monospaced)
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .textSelection(.enabled)
        }
    }
}

public enum BadgeTone {
    case neutral, good, warning, bad, info

    var color: Color {
        switch self {
        case .neutral: return .secondary
        case .good: return .green
        case .warning: return .orange
        case .bad: return .red
        case .info: return .accentColor
        }
    }
}

public struct StatusBadge: View {
    let text: String
    let tone: BadgeTone

    public init(_ text: String, tone: BadgeTone = .neutral) {
        self.text = text
        self.tone = tone
    }

    public var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tone.color.opacity(0.15), in: Capsule())
            .foregroundStyle(tone.color)
    }
}

/// 依据服务端常见状态字符串推断色调。
public func badgeTone(for raw: String?) -> BadgeTone {
    guard let raw = raw?.lowercased() else { return .neutral }
    if ["running", "active", "online", "success", "ok", "healthy", "completed", "done", "已完成", "运行", "在线", "成功"]
        .contains(where: { raw.contains($0) }) { return .good }
    if ["error", "failed", "fail", "offline", "dead", "exited", "失败", "离线", "异常"]
        .contains(where: { raw.contains($0) }) { return .bad }
    if ["pending", "waiting", "queued", "paused", "restarting", "warning", "等待", "暂停", "排队"]
        .contains(where: { raw.contains($0) }) { return .warning }
    return .neutral
}

// MARK: - 卡片

public struct MetricTile: View {
    let title: String
    let value: String
    var detail: String?
    var systemImage: String?
    var tone: BadgeTone = .info

    public init(title: String, value: String, detail: String? = nil,
                systemImage: String? = nil, tone: BadgeTone = .info) {
        self.title = title
        self.value = value
        self.detail = detail
        self.systemImage = systemImage
        self.tone = tone
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption)
                        .foregroundStyle(tone.color)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12))
    }
}

public struct CardSection<Content: View>: View {
    let title: String
    var systemImage: String?
    var trailing: AnyView?
    @ViewBuilder var content: () -> Content

    public init(title: String, systemImage: String? = nil, trailing: AnyView? = nil,
                @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.trailing = trailing
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: systemImage ?? "square.grid.2x2")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let trailing { trailing }
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
    }
}

/// 带百分比的横向进度条（CPU/内存/磁盘等）。
public struct GaugeRow: View {
    let title: String
    let ratio: Double
    let caption: String

    public init(title: String, ratio: Double, caption: String) {
        self.title = title
        self.ratio = min(max(ratio.isFinite ? ratio : 0, 0), 1)
        self.caption = caption
    }

    private var tone: Color {
        if ratio > 0.9 { return .red }
        if ratio > 0.75 { return .orange }
        return .accentColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(caption).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            ProgressView(value: ratio)
                .tint(tone)
        }
    }
}

// MARK: - 图片

@MainActor
final class ImageMemoryCache {
    static let shared = ImageMemoryCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 400
        cache.totalCostLimit = 80 * 1024 * 1024
    }

    func image(for key: String) -> UIImage? { cache.object(forKey: key as NSString) }

    func store(_ image: UIImage, for key: String) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}

/// 走当前服务器会话加载图片（图片代理接口需要 Cookie/Token）。
public struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var placeholderIcon: String = "photo"

    @EnvironmentObject private var session: AppSession
    @State private var image: UIImage?
    @State private var failed = false

    public init(url: URL?, contentMode: ContentMode = .fill, placeholderIcon: String = "photo") {
        self.url = url
        self.contentMode = contentMode
        self.placeholderIcon = placeholderIcon
    }

    public var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Rectangle()
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .overlay {
                        Image(systemName: failed ? "photo.badge.exclamationmark" : placeholderIcon)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .clipped()
        .task(id: url?.absoluteString) { await load() }
    }

    private func load() async {
        guard let url else { return }
        let key = url.absoluteString
        if let cached = ImageMemoryCache.shared.image(for: key) {
            image = cached
            return
        }
        do {
            let data: Data
            if let client = session.client {
                data = try await client.data(from: url, timeout: 30)
            } else {
                data = try await URLSession.shared.data(from: url).0
            }
            guard let decoded = UIImage(data: data) else {
                failed = true
                return
            }
            ImageMemoryCache.shared.store(decoded, for: key)
            image = decoded
        } catch {
            failed = true
        }
    }
}

/// 海报卡片：发现、缺集统计、最近入库都用它。
public struct PosterCard: View {
    let title: String
    var subtitle: String?
    var badge: String?
    var url: URL?
    var width: CGFloat = 112

    public init(title: String, subtitle: String? = nil, badge: String? = nil,
                url: URL? = nil, width: CGFloat = 112) {
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.url = url
        self.width = width
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RemoteImage(url: url, placeholderIcon: "film")
                .frame(width: width, height: width * 1.5)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .topLeading) {
                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.55), in: Capsule())
                            .foregroundStyle(.white)
                            .padding(6)
                    }
                }
            Text(title)
                .font(.caption.weight(.medium))
                .lineLimit(2)
                .frame(width: width, alignment: .leading)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: width, alignment: .leading)
            }
        }
    }
}

// MARK: - JSON 检视

/// 原样展示任意 JSON 的整页视图，作为「服务端返回结构未在 OpenAPI 声明」时的兜底。
public struct JSONRawScreen: View {
    let value: JSONValue
    var title: String = "原始数据"

    public init(value: JSONValue, title: String = "原始数据") {
        self.value = value
        self.title = title
    }

    public var body: some View {
        ScrollView([.vertical, .horizontal]) {
            Text(value.prettyPrinted)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = value.prettyPrinted
                } label: {
                    Image(systemName: "doc.on.doc")
                }
            }
        }
    }
}

/// 列表里的「原始数据」入口行，点击后推入整页 JSON。
/// 直接把 `JSONRawScreen` 塞进 List 行会造成嵌套滚动视图，所以统一走这个入口。
public struct JSONInspector: View {
    let value: JSONValue
    var title: String = "原始数据"

    public init(value: JSONValue, title: String = "原始数据") {
        self.value = value
        self.title = title
    }

    public var body: some View {
        NavigationLink {
            JSONRawScreen(value: value, title: title)
        } label: {
            Label(title, systemImage: "curlybraces")
        }
    }
}

/// 把任意 JSON 对象铺成键值行；嵌套结构提供下钻入口。
public struct JSONFieldList: View {
    let value: JSONValue
    var skipKeys: Set<String> = []

    public init(value: JSONValue, skipKeys: Set<String> = []) {
        self.value = value
        self.skipKeys = skipKeys
    }

    public var body: some View {
        ForEach(value.sortedPairs.filter { !skipKeys.contains($0.key) }, id: \.key) { pair in
            switch pair.value {
            case .object, .array:
                NavigationLink {
                    List { JSONFieldList(value: pair.value) }
                        .navigationTitle(pair.key)
                } label: {
                    HStack {
                        Text(pair.key)
                        Spacer()
                        Text(summary(of: pair.value))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            default:
                KeyValueRow(pair.key, Fmt.text(pair.value))
            }
        }
        if value.sortedPairs.isEmpty, let items = value.array {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if item.object != nil {
                    NavigationLink("#\(index + 1) " + (item.first(of: "name", "title", "id").displayString ?? "")) {
                        List { JSONFieldList(value: item) }
                            .navigationTitle("#\(index + 1)")
                    }
                } else {
                    Text(Fmt.text(item))
                }
            }
        }
    }

    private func summary(of value: JSONValue) -> String {
        if let a = value.array { return "\(a.count) 项" }
        if let o = value.object { return "\(o.count) 字段" }
        return "—"
    }
}
