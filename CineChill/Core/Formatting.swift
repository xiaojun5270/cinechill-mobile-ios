import Foundation

/// 展示层格式化工具。所有数值转换先做有限性校验，避免脏数据导致崩溃。
public enum Fmt {
    public static func bytes(_ value: Double?) -> String {
        guard let value, value.isFinite, value >= 0 else { return "—" }
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var v = value
        var idx = 0
        while v >= 1024, idx < units.count - 1 {
            v /= 1024
            idx += 1
        }
        if idx == 0 { return "\(Int(v)) B" }
        return String(format: v >= 100 ? "%.0f %@" : "%.1f %@", v, units[idx])
    }

    public static func bytes(_ value: JSONValue) -> String { bytes(value.double) }

    public static func speed(_ value: JSONValue) -> String {
        guard let d = value.double, d.isFinite else { return "—" }
        return bytes(d) + "/s"
    }

    public static func percent(_ value: Double?, digits: Int = 0) -> String {
        guard let value, value.isFinite else { return "—" }
        let scaled = value <= 1.0001 && value >= -0.0001 ? value * 100 : value
        return String(format: "%.\(digits)f%%", min(max(scaled, 0), 999))
    }

    public static func percent(_ value: JSONValue, digits: Int = 0) -> String {
        percent(value.double, digits: digits)
    }

    /// 0…1 之间的进度值，越界会被裁剪。
    public static func ratio(_ value: JSONValue) -> Double {
        guard let d = value.double, d.isFinite else { return 0 }
        let scaled = d > 1 ? d / 100 : d
        return min(max(scaled, 0), 1)
    }

    public static func count(_ value: JSONValue) -> String {
        guard let i = value.int else { return "—" }
        if abs(i) >= 10000 {
            return String(format: "%.1f万", Double(i) / 10000)
        }
        return String(i)
    }

    public static func duration(seconds: Double?) -> String {
        guard let seconds, seconds.isFinite, seconds >= 0 else { return "—" }
        let total = Int(min(seconds, 3.15e8))
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if d > 0 { return "\(d)天\(h)小时" }
        if h > 0 { return "\(h)小时\(m)分" }
        if m > 0 { return "\(m)分\(s)秒" }
        return "\(s)秒"
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let plainFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_Hans_CN")
        f.dateFormat = "MM-dd HH:mm"
        return f
    }()

    private static let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_Hans_CN")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    /// 兼容 ISO8601、`yyyy-MM-dd HH:mm:ss`、秒级与毫秒级时间戳。
    public static func date(_ value: JSONValue) -> Date? {
        if let number = value.double, number > 1_000_000 {
            let seconds = number > 3_000_000_000 ? number / 1000 : number
            guard seconds.isFinite, seconds < 4_000_000_000 else { return nil }
            return Date(timeIntervalSince1970: seconds)
        }
        guard let text = value.string, !text.isEmpty else { return nil }
        if let d = isoFormatter.date(from: text) { return d }
        if let d = isoPlain.date(from: text) { return d }
        if let d = plainFormatter.date(from: text) { return d }
        if let seconds = Double(text), seconds > 1_000_000, seconds < 4_000_000_000 {
            return Date(timeIntervalSince1970: seconds)
        }
        return nil
    }

    public static func dateTime(_ value: JSONValue) -> String {
        guard let d = date(value) else { return value.displayString ?? "—" }
        return displayFormatter.string(from: d)
    }

    public static func fullDateTime(_ value: JSONValue) -> String {
        guard let d = date(value) else { return value.displayString ?? "—" }
        return fullFormatter.string(from: d)
    }

    public static func relative(_ value: JSONValue) -> String {
        guard let d = date(value) else { return value.displayString ?? "—" }
        let delta = Date().timeIntervalSince(d)
        if abs(delta) < 60 { return "刚刚" }
        if delta > 0 {
            if delta < 3600 { return "\(Int(delta / 60)) 分钟前" }
            if delta < 86400 { return "\(Int(delta / 3600)) 小时前" }
            if delta < 86400 * 30 { return "\(Int(delta / 86400)) 天前" }
            return displayFormatter.string(from: d)
        }
        let ahead = -delta
        if ahead < 3600 { return "\(Int(ahead / 60)) 分钟后" }
        if ahead < 86400 { return "\(Int(ahead / 3600)) 小时后" }
        return displayFormatter.string(from: d)
    }

    /// 把 5 段 cron 翻成中文摘要，不认识的原样返回。
    public static func cron(_ expression: String?) -> String {
        guard let expression, !expression.trimmingCharacters(in: .whitespaces).isEmpty else { return "未设置" }
        let parts = expression.split(separator: " ").map(String.init)
        guard parts.count == 5 else { return expression }
        let (minute, hour, day, month, weekday) = (parts[0], parts[1], parts[2], parts[3], parts[4])
        func pad(_ s: String) -> String { s.count == 1 ? "0" + s : s }
        if minute.hasPrefix("*/"), hour == "*" { return "每 \(minute.dropFirst(2)) 分钟" }
        if hour.hasPrefix("*/") { return "每 \(hour.dropFirst(2)) 小时" }
        if day == "*", month == "*", weekday == "*", let _ = Int(minute), let _ = Int(hour) {
            return "每天 \(pad(hour)):\(pad(minute))"
        }
        if weekday != "*", day == "*" {
            let names = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
            if let index = Int(weekday), index >= 0, index < names.count {
                return "每\(names[index]) \(pad(hour)):\(pad(minute))"
            }
        }
        if day != "*", month == "*" {
            return "每月 \(day) 日 \(pad(hour)):\(pad(minute))"
        }
        return expression
    }

    public static func text(_ value: JSONValue, fallback: String = "—") -> String {
        guard let s = value.displayString, !s.isEmpty else { return fallback }
        return s
    }
}
