import Foundation

/// 服务端 200 响应在 OpenAPI 中全部未声明 schema（303/303 个操作均为空 schema），
/// 因此统一用 `JSONValue` 承载，读取时按需做防御式取值。
public enum JSONValue: Codable, Hashable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    // MARK: - Decoding

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() {
            self = .null
        } else if let v = try? c.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? c.decode(Int.self) {
            self = .int(v)
        } else if let v = try? c.decode(Double.self) {
            self = .double(v)
        } else if let v = try? c.decode(String.self) {
            self = .string(v)
        } else if let v = try? c.decode([JSONValue].self) {
            self = .array(v)
        } else if let v = try? c.decode([String: JSONValue].self) {
            self = .object(v)
        } else {
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let v): try c.encode(v)
        case .int(let v): try c.encode(v)
        case .double(let v): try c.encode(v.isFinite ? v : 0)
        case .string(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .object(let v): try c.encode(v)
        }
    }

    // MARK: - Construction

    public init(_ any: Any?) {
        switch any {
        case nil, is NSNull:
            self = .null
        case let v as JSONValue:
            self = v
        case let v as Bool:
            self = .bool(v)
        case let v as Int:
            self = .int(v)
        case let v as Double:
            self = v.isFinite ? .double(v) : .null
        case let v as String:
            self = .string(v)
        case let v as [Any?]:
            self = .array(v.map { JSONValue($0) })
        case let v as [String: Any?]:
            self = .object(v.mapValues { JSONValue($0) })
        default:
            self = .null
        }
    }

    public static func of(_ pairs: [String: JSONValue]) -> JSONValue { .object(pairs) }

    // MARK: - Access

    public subscript(key: String) -> JSONValue {
        get {
            if case .object(let dict) = self { return dict[key] ?? .null }
            return .null
        }
        set {
            var dict = object ?? [:]
            if newValue.isNull {
                dict.removeValue(forKey: key)
            } else {
                dict[key] = newValue
            }
            self = .object(dict)
        }
    }

    public subscript(index: Int) -> JSONValue {
        get {
            if case .array(let items) = self, index >= 0, index < items.count { return items[index] }
            return .null
        }
        set {
            var items = array ?? []
            guard index >= 0 else { return }
            while items.count <= index { items.append(.null) }
            items[index] = newValue
            self = .array(items)
        }
    }

    /// 在数组末尾追加元素；当前不是数组时自动转成数组。
    public mutating func append(_ value: JSONValue) {
        var items = array ?? []
        items.append(value)
        self = .array(items)
    }

    /// 删除数组中的元素。
    public mutating func remove(at index: Int) {
        guard var items = array, index >= 0, index < items.count else { return }
        items.remove(at: index)
        self = .array(items)
    }

    /// 支持 `json.path("data", "items")` 逐层下钻。
    public func path(_ keys: String...) -> JSONValue {
        var current = self
        for k in keys { current = current[k] }
        return current
    }

    /// 依次尝试多个键名，返回第一个非空值（服务端字段命名不完全统一时很实用）。
    public func first(of keys: String...) -> JSONValue {
        for k in keys {
            let v = self[k]
            if !v.isNull { return v }
        }
        return .null
    }

    /// 逐层广度优先查找候选键。服务端常把统计值包在 `data`/`library`/`emby` 等外层里，
    /// 用它可以在不确定层级的情况下拿到值；找不到时返回 `.null`。
    public func deepFirst(_ keys: [String], maxDepth: Int = 3) -> JSONValue {
        var frontier: [JSONValue] = [self]
        var depth = 0
        while !frontier.isEmpty, depth <= maxDepth {
            for key in keys {
                for node in frontier {
                    let v = node[key]
                    if !v.isNull { return v }
                }
            }
            var next: [JSONValue] = []
            for node in frontier {
                if let obj = node.object {
                    next.append(contentsOf: obj.keys.sorted().compactMap { obj[$0] })
                }
            }
            frontier = next
            depth += 1
        }
        return .null
    }

    public func deepFirst(of keys: String...) -> JSONValue { deepFirst(keys) }

    public var isNull: Bool { if case .null = self { return true }; return false }

    public var string: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    /// 宽松取字符串：数字/布尔也会转成可展示文本。
    public var displayString: String? {
        switch self {
        case .string(let v): return v
        case .int(let v): return String(v)
        case .double(let v): return v.isFinite ? Self.trimmed(v) : nil
        case .bool(let v): return v ? "是" : "否"
        default: return nil
        }
    }

    public var bool: Bool? {
        switch self {
        case .bool(let v): return v
        case .int(let v): return v != 0
        case .string(let v):
            switch v.lowercased() {
            case "true", "1", "yes", "on": return true
            case "false", "0", "no", "off": return false
            default: return nil
            }
        default: return nil
        }
    }

    /// 安全的 Double：拒绝 NaN / Inf，避免下游 `Int(...)` 触发崩溃。
    public var double: Double? {
        switch self {
        case .double(let v): return v.isFinite ? v : nil
        case .int(let v): return Double(v)
        case .bool(let v): return v ? 1 : 0
        case .string(let v):
            guard let d = Double(v), d.isFinite else { return nil }
            return d
        default: return nil
        }
    }

    /// 安全的 Int：先经过有限性与范围校验再转换。
    public var int: Int? {
        switch self {
        case .int(let v): return v
        case .bool(let v): return v ? 1 : 0
        case .double(let v):
            guard v.isFinite, v >= -9.0e18, v <= 9.0e18 else { return nil }
            return Int(v)
        case .string(let v):
            if let i = Int(v) { return i }
            guard let d = Double(v), d.isFinite, d >= -9.0e18, d <= 9.0e18 else { return nil }
            return Int(d)
        default: return nil
        }
    }

    public var array: [JSONValue]? {
        if case .array(let v) = self { return v }
        return nil
    }

    public var object: [String: JSONValue]? {
        if case .object(let v) = self { return v }
        return nil
    }

    /// 数组读取的兜底：对象包裹的列表（`{"items": [...]}` 之类）也能取出。
    public func list(_ keys: String...) -> [JSONValue] {
        if let a = array { return a }
        for k in keys {
            if let a = self[k].array { return a }
        }
        for k in ["items", "data", "list", "results", "records", "rows", "tasks", "containers"] {
            if let a = self[k].array { return a }
        }
        return []
    }

    /// 键值对按键名排序，便于稳定渲染。
    public var sortedPairs: [(key: String, value: JSONValue)] {
        guard let obj = object else { return [] }
        return obj.keys.sorted().map { (key: $0, value: obj[$0] ?? .null) }
    }

    public var isEmptyContainer: Bool {
        switch self {
        case .array(let a): return a.isEmpty
        case .object(let o): return o.isEmpty
        case .null: return true
        default: return false
        }
    }

    /// 服务端约定的成功标记，兼容 success / ok / status 三种写法。
    public var isSuccessFlag: Bool {
        if let b = self["success"].bool { return b }
        if let b = self["ok"].bool { return b }
        if let s = self["status"].string { return s == "ok" || s == "success" }
        return true
    }

    /// 服务端错误文案，兼容顶层或 data/result 等对象内嵌套的常见错误结构。
    public var errorMessage: String? {
        let keys = ["detail", "message", "error", "msg", "reason", "errors"]
        var frontier = [self]
        var depth = 0

        while !frontier.isEmpty, depth <= 4 {
            for node in frontier {
                guard let object = node.object else { continue }
                for key in keys {
                    guard let value = object[key],
                          let message = Self.errorText(from: value),
                          !message.isEmpty else { continue }
                    return message
                }
            }

            frontier = frontier.flatMap { node -> [JSONValue] in
                if let object = node.object { return Array(object.values) }
                if let array = node.array { return array }
                return []
            }
            depth += 1
        }
        return nil
    }

    private static func errorText(from value: JSONValue) -> String? {
        if let string = value.string {
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let array = value.array {
            let messages = array.compactMap { item -> String? in
                for key in ["msg", "message", "detail", "error", "reason"] {
                    if let text = errorText(from: item[key]), !text.isEmpty { return text }
                }
                return item.displayString
            }
            return messages.isEmpty ? nil : messages.joined(separator: "; ")
        }
        if let object = value.object {
            for key in ["msg", "message", "detail", "error", "reason"] {
                if let nested = object[key],
                   let text = errorText(from: nested),
                   !text.isEmpty { return text }
            }
        }
        return nil
    }

    public var prettyPrinted: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(self),
              let text = String(data: data, encoding: .utf8) else { return "—" }
        return text
    }

    private static func trimmed(_ v: Double) -> String {
        if v == v.rounded(), abs(v) < 1e15 { return String(Int(v)) }
        return String(format: "%.2f", v)
    }
}

extension JSONValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral,
                     ExpressibleByBooleanLiteral, ExpressibleByFloatLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
    public init(integerLiteral value: Int) { self = .int(value) }
    public init(booleanLiteral value: Bool) { self = .bool(value) }
    public init(floatLiteral value: Double) { self = value.isFinite ? .double(value) : .null }
}

extension JSONValue: ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    public init(arrayLiteral elements: JSONValue...) { self = .array(elements) }
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(Dictionary(elements, uniquingKeysWith: { _, last in last }))
    }
}

extension JSONValue: CustomStringConvertible {
    public var description: String { displayString ?? prettyPrinted }
}

public extension JSONValue {
    /// 把动态 JSON 转成生成的强类型模型（用于只接受具体 body 的保存接口）。
    /// 模型的所有字段都有默认值，因此缺字段时会回落到默认值。
    func decoded<T: Decodable>(_ type: T.Type) throws -> T {
        let data = try JSONEncoder().encode(self)
        return try JSONDecoder().decode(type, from: data)
    }

    /// 把强类型模型转回 JSON，便于交给通用编辑器展示。
    static func encoding<T: Encodable>(_ value: T) -> JSONValue {
        guard let data = try? JSONEncoder().encode(value),
              let decoded = try? JSONDecoder().decode(JSONValue.self, from: data) else { return .null }
        return decoded
    }
}
