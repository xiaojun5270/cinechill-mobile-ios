// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// SaveEmbyPayload
public struct SaveEmbyPayload: Codable, Hashable, Sendable {
    public var embys: [Emby302Config]

    public init(embys: [Emby302Config] = []) {
        self.embys = embys
    }

    enum CodingKeys: String, CodingKey {
        case embys
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.embys = try c.decodeIfPresent([Emby302Config].self, forKey: .embys) ?? []
    }
}

/// ScanPayload
public struct ScanPayload: Codable, Hashable, Sendable {
    public var force: Bool

    public init(force: Bool = true) {
        self.force = force
    }

    enum CodingKeys: String, CodingKey {
        case force
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.force = try c.decodeIfPresent(Bool.self, forKey: .force) ?? true
    }
}

/// ScheduledRestartPayload
public struct ScheduledRestartPayload: Codable, Hashable, Sendable {
    public var enabled: Bool
    public var mode: String
    public var time: String
    public var memoryLimitMb: Double
    public var memoryDurationMinutes: Double

    public init(enabled: Bool = false, mode: String = "time", time: String = "", memoryLimitMb: Double = 0.0, memoryDurationMinutes: Double = 15.0) {
        self.enabled = enabled
        self.mode = mode
        self.time = time
        self.memoryLimitMb = memoryLimitMb
        self.memoryDurationMinutes = memoryDurationMinutes
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case mode
        case time
        case memoryLimitMb = "memory_limit_mb"
        case memoryDurationMinutes = "memory_duration_minutes"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        self.mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "time"
        self.time = try c.decodeIfPresent(String.self, forKey: .time) ?? ""
        self.memoryLimitMb = try c.decodeIfPresent(Double.self, forKey: .memoryLimitMb) ?? 0.0
        self.memoryDurationMinutes = try c.decodeIfPresent(Double.self, forKey: .memoryDurationMinutes) ?? 15.0
    }
}

/// StandardTopologyDirsPayload
public struct StandardTopologyDirsPayload: Codable, Hashable, Sendable {
    public var localMediaRoot: String
    public var remoteRootName: String

    public init(localMediaRoot: String, remoteRootName: String = "影视库") {
        self.localMediaRoot = localMediaRoot
        self.remoteRootName = remoteRootName
    }

    enum CodingKeys: String, CodingKey {
        case localMediaRoot = "local_media_root"
        case remoteRootName = "remote_root_name"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.localMediaRoot = try c.decode(String.self, forKey: .localMediaRoot)
        self.remoteRootName = try c.decodeIfPresent(String.self, forKey: .remoteRootName) ?? "影视库"
    }
}

/// Start115QrPayload
public struct Start115QrPayload: Codable, Hashable, Sendable {
    public var app: String

    public init(app: String = "115android") {
        self.app = app
    }

    enum CodingKeys: String, CodingKey {
        case app
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.app = try c.decodeIfPresent(String.self, forKey: .app) ?? "115android"
    }
}

/// Status115QrPayload
public struct Status115QrPayload: Codable, Hashable, Sendable {
    public var uid: String
    public var time: Int
    public var sign: String

    public init(uid: String, time: Int, sign: String) {
        self.uid = uid
        self.time = time
        self.sign = sign
    }

    enum CodingKeys: String, CodingKey {
        case uid
        case time
        case sign
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try c.decode(String.self, forKey: .uid)
        self.time = try c.decode(Int.self, forKey: .time)
        self.sign = try c.decode(String.self, forKey: .sign)
    }
}

/// StrmConfigPayload
public struct StrmConfigPayload: Codable, Hashable, Sendable {
    public var syncTasks: [StrmSyncTask]

    public init(syncTasks: [StrmSyncTask] = []) {
        self.syncTasks = syncTasks
    }

    enum CodingKeys: String, CodingKey {
        case syncTasks = "sync_tasks"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.syncTasks = try c.decodeIfPresent([StrmSyncTask].self, forKey: .syncTasks) ?? []
    }
}

/// StrmStartPayload
public struct StrmStartPayload: Codable, Hashable, Sendable {
    public var taskIndex: Int
    public var mode: String

    public init(taskIndex: Int = 0, mode: String = "full") {
        self.taskIndex = taskIndex
        self.mode = mode
    }

    enum CodingKeys: String, CodingKey {
        case taskIndex = "task_index"
        case mode
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.taskIndex = try c.decodeIfPresent(Int.self, forKey: .taskIndex) ?? 0
        self.mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "full"
    }
}

/// StrmStopPayload
public struct StrmStopPayload: Codable, Hashable, Sendable {
    public var runId: String

    public init(runId: String = "") {
        self.runId = runId
    }

    enum CodingKeys: String, CodingKey {
        case runId = "run_id"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.runId = try c.decodeIfPresent(String.self, forKey: .runId) ?? ""
    }
}

/// StrmSyncTask
public struct StrmSyncTask: Codable, Hashable, Sendable {
    public var name: String
    public var driveIndex: Int
    public var remotePath: String
    public var localPath: String
    public var downloadAuxiliary: Bool
    public var strmUrlBase: String
    public var minVideoSizeMb: Int
    public var videoExtsStr: String
    public var audioExtsStr: String
    public var imageExtsStr: String
    public var dataExtsStr: String
    public var pollInterval: Int
    public var overwrite: String
    public var auxDownloadMode: String
    public var mode: String

    public init(name: String = "标准媒体库同步", driveIndex: Int = 0, remotePath: String = "", localPath: String = "", downloadAuxiliary: Bool = true, strmUrlBase: String = "", minVideoSizeMb: Int = 0, videoExtsStr: String = ".mp4,.mpg,.mkv,.mpeg,.ts,.vob,.m4v,.avi,.3gp,.wmv,.webm,.flv,.mov,.m2ts,.rmvb,.rm,.asf,.f4v,.m2t,.mts,.mpe,.tp,.trp,.divx,.ogv,.dv", audioExtsStr: String = ".mp3,.flac,.wav,.m4a,.ape,.dsd,.dff,.dsf,.ac3,.dts", imageExtsStr: String = ".jpg,.jpeg,.png,.webp,.bmp,.tiff,.tif,.ico,.gif,.svg,.heic,.avif,.raw", dataExtsStr: String = ".nfo,.lrc,.srt,.pdf,.ass,.ssa,.md,.sub,.sup,.idx,.txt,.xml,.json,.smi,.vtt,.ttml,.dfxp,.scc,.bup,.ifo", pollInterval: Int = 60, overwrite: String = "skip", auxDownloadMode: String = "cdn", mode: String = "full") {
        self.name = name
        self.driveIndex = driveIndex
        self.remotePath = remotePath
        self.localPath = localPath
        self.downloadAuxiliary = downloadAuxiliary
        self.strmUrlBase = strmUrlBase
        self.minVideoSizeMb = minVideoSizeMb
        self.videoExtsStr = videoExtsStr
        self.audioExtsStr = audioExtsStr
        self.imageExtsStr = imageExtsStr
        self.dataExtsStr = dataExtsStr
        self.pollInterval = pollInterval
        self.overwrite = overwrite
        self.auxDownloadMode = auxDownloadMode
        self.mode = mode
    }

    enum CodingKeys: String, CodingKey {
        case name
        case driveIndex = "drive_index"
        case remotePath = "remote_path"
        case localPath = "local_path"
        case downloadAuxiliary = "download_auxiliary"
        case strmUrlBase = "strm_url_base"
        case minVideoSizeMb = "min_video_size_mb"
        case videoExtsStr = "video_exts_str"
        case audioExtsStr = "audio_exts_str"
        case imageExtsStr = "image_exts_str"
        case dataExtsStr = "data_exts_str"
        case pollInterval = "poll_interval"
        case overwrite
        case auxDownloadMode = "aux_download_mode"
        case mode
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? "标准媒体库同步"
        self.driveIndex = try c.decodeIfPresent(Int.self, forKey: .driveIndex) ?? 0
        self.remotePath = try c.decodeIfPresent(String.self, forKey: .remotePath) ?? ""
        self.localPath = try c.decodeIfPresent(String.self, forKey: .localPath) ?? ""
        self.downloadAuxiliary = try c.decodeIfPresent(Bool.self, forKey: .downloadAuxiliary) ?? true
        self.strmUrlBase = try c.decodeIfPresent(String.self, forKey: .strmUrlBase) ?? ""
        self.minVideoSizeMb = try c.decodeIfPresent(Int.self, forKey: .minVideoSizeMb) ?? 0
        self.videoExtsStr = try c.decodeIfPresent(String.self, forKey: .videoExtsStr) ?? ".mp4,.mpg,.mkv,.mpeg,.ts,.vob,.m4v,.avi,.3gp,.wmv,.webm,.flv,.mov,.m2ts,.rmvb,.rm,.asf,.f4v,.m2t,.mts,.mpe,.tp,.trp,.divx,.ogv,.dv"
        self.audioExtsStr = try c.decodeIfPresent(String.self, forKey: .audioExtsStr) ?? ".mp3,.flac,.wav,.m4a,.ape,.dsd,.dff,.dsf,.ac3,.dts"
        self.imageExtsStr = try c.decodeIfPresent(String.self, forKey: .imageExtsStr) ?? ".jpg,.jpeg,.png,.webp,.bmp,.tiff,.tif,.ico,.gif,.svg,.heic,.avif,.raw"
        self.dataExtsStr = try c.decodeIfPresent(String.self, forKey: .dataExtsStr) ?? ".nfo,.lrc,.srt,.pdf,.ass,.ssa,.md,.sub,.sup,.idx,.txt,.xml,.json,.smi,.vtt,.ttml,.dfxp,.scc,.bup,.ifo"
        self.pollInterval = try c.decodeIfPresent(Int.self, forKey: .pollInterval) ?? 60
        self.overwrite = try c.decodeIfPresent(String.self, forKey: .overwrite) ?? "skip"
        self.auxDownloadMode = try c.decodeIfPresent(String.self, forKey: .auxDownloadMode) ?? "cdn"
        self.mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "full"
    }
}

/// SubscribeRequest
public struct SubscribeRequest: Codable, Hashable, Sendable {
    public var tmdbid: Int
    public var typeName: String
    public var season: Int?
    public var name: String?
    public var year: String?

    public init(tmdbid: Int, typeName: String = "movie", season: Int? = nil, name: String? = nil, year: String? = nil) {
        self.tmdbid = tmdbid
        self.typeName = typeName
        self.season = season
        self.name = name
        self.year = year
    }

    enum CodingKeys: String, CodingKey {
        case tmdbid
        case typeName = "type_name"
        case season
        case name
        case year
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.tmdbid = try c.decode(Int.self, forKey: .tmdbid)
        self.typeName = try c.decodeIfPresent(String.self, forKey: .typeName) ?? "movie"
        self.season = try c.decodeIfPresent(Int.self, forKey: .season)
        self.name = try c.decodeIfPresent(String.self, forKey: .name)
        self.year = try c.decodeIfPresent(String.self, forKey: .year)
    }
}

/// SuiteBackupRequest
public struct SuiteBackupRequest: Codable, Hashable, Sendable {
    public var url: String
    public var key: String
    public var publicHost: String?
    public var suiteName: String

    public init(url: String, key: String, publicHost: String? = nil, suiteName: String) {
        self.url = url
        self.key = key
        self.publicHost = publicHost
        self.suiteName = suiteName
    }

    enum CodingKeys: String, CodingKey {
        case url
        case key
        case publicHost = "public_host"
        case suiteName = "suite_name"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try c.decode(String.self, forKey: .url)
        self.key = try c.decode(String.self, forKey: .key)
        self.publicHost = try c.decodeIfPresent(String.self, forKey: .publicHost)
        self.suiteName = try c.decode(String.self, forKey: .suiteName)
    }
}

/// SuiteContentRequest
public struct SuiteContentRequest: Codable, Hashable, Sendable {
    public var suiteName: String

    public init(suiteName: String) {
        self.suiteName = suiteName
    }

    enum CodingKeys: String, CodingKey {
        case suiteName = "suite_name"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.suiteName = try c.decode(String.self, forKey: .suiteName)
    }
}

/// SuiteRestoreRequest
public struct SuiteRestoreRequest: Codable, Hashable, Sendable {
    public var url: String
    public var key: String
    public var publicHost: String?
    public var suiteName: String
    public var targetIds: [JSONValue]

    public init(url: String, key: String, publicHost: String? = nil, suiteName: String, targetIds: [JSONValue] = []) {
        self.url = url
        self.key = key
        self.publicHost = publicHost
        self.suiteName = suiteName
        self.targetIds = targetIds
    }

    enum CodingKeys: String, CodingKey {
        case url
        case key
        case publicHost = "public_host"
        case suiteName = "suite_name"
        case targetIds = "target_ids"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try c.decode(String.self, forKey: .url)
        self.key = try c.decode(String.self, forKey: .key)
        self.publicHost = try c.decodeIfPresent(String.self, forKey: .publicHost)
        self.suiteName = try c.decode(String.self, forKey: .suiteName)
        self.targetIds = try c.decodeIfPresent([JSONValue].self, forKey: .targetIds) ?? []
    }
}

/// TaskTarget
public struct TaskTarget: Codable, Hashable, Sendable {
    public var serverIdx: Int
    public var libraryId: String
    public var libraryName: String
    public var url: String?
    public var key: String?
    public var publicHost: String?

    public init(serverIdx: Int = 0, libraryId: String, libraryName: String = "Unknown", url: String? = nil, key: String? = nil, publicHost: String? = nil) {
        self.serverIdx = serverIdx
        self.libraryId = libraryId
        self.libraryName = libraryName
        self.url = url
        self.key = key
        self.publicHost = publicHost
    }

    enum CodingKeys: String, CodingKey {
        case serverIdx = "server_idx"
        case libraryId = "library_id"
        case libraryName = "library_name"
        case url
        case key
        case publicHost = "public_host"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.serverIdx = try c.decodeIfPresent(Int.self, forKey: .serverIdx) ?? 0
        self.libraryId = try c.decode(String.self, forKey: .libraryId)
        self.libraryName = try c.decodeIfPresent(String.self, forKey: .libraryName) ?? "Unknown"
        self.url = try c.decodeIfPresent(String.self, forKey: .url)
        self.key = try c.decodeIfPresent(String.self, forKey: .key)
        self.publicHost = try c.decodeIfPresent(String.self, forKey: .publicHost)
    }
}

/// TelegramDialogsRequest
public struct TelegramDialogsRequest: Codable, Hashable, Sendable {
    public var selectedDialogs: [JSONValue]?

    public init(selectedDialogs: [JSONValue]? = nil) {
        self.selectedDialogs = selectedDialogs
    }

    enum CodingKeys: String, CodingKey {
        case selectedDialogs = "selected_dialogs"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.selectedDialogs = try c.decodeIfPresent([JSONValue].self, forKey: .selectedDialogs)
    }
}

/// TelegramNotifyConfigModel
public struct TelegramNotifyConfigModel: Codable, Hashable, Sendable {
    public var enabled: Bool
    public var name: String
    public var botToken: String
    public var chatId: String
    public var accountMonitorEnabled: Bool
    public var apiId: String
    public var apiHash: String
    public var phone: String
    public var selectedDialogs: [JSONValue]?
    public var monitorReplyEnabled: Bool
    public var monitorTransferMode: String
    public var transferDirMode: String
    public var transferDir: String
    public var notifyTypes: JSONValue?
    public var templates: JSONValue

    public init(enabled: Bool = false, name: String = "Telegram", botToken: String = "", chatId: String = "", accountMonitorEnabled: Bool = false, apiId: String = "", apiHash: String = "", phone: String = "", selectedDialogs: [JSONValue]? = nil, monitorReplyEnabled: Bool = false, monitorTransferMode: String = "all", transferDirMode: String = "system", transferDir: String = "", notifyTypes: JSONValue? = nil, templates: JSONValue = .object([:])) {
        self.enabled = enabled
        self.name = name
        self.botToken = botToken
        self.chatId = chatId
        self.accountMonitorEnabled = accountMonitorEnabled
        self.apiId = apiId
        self.apiHash = apiHash
        self.phone = phone
        self.selectedDialogs = selectedDialogs
        self.monitorReplyEnabled = monitorReplyEnabled
        self.monitorTransferMode = monitorTransferMode
        self.transferDirMode = transferDirMode
        self.transferDir = transferDir
        self.notifyTypes = notifyTypes
        self.templates = templates
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case name
        case botToken = "bot_token"
        case chatId = "chat_id"
        case accountMonitorEnabled = "account_monitor_enabled"
        case apiId = "api_id"
        case apiHash = "api_hash"
        case phone
        case selectedDialogs = "selected_dialogs"
        case monitorReplyEnabled = "monitor_reply_enabled"
        case monitorTransferMode = "monitor_transfer_mode"
        case transferDirMode = "transfer_dir_mode"
        case transferDir = "transfer_dir"
        case notifyTypes = "notify_types"
        case templates
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Telegram"
        self.botToken = try c.decodeIfPresent(String.self, forKey: .botToken) ?? ""
        self.chatId = try c.decodeIfPresent(String.self, forKey: .chatId) ?? ""
        self.accountMonitorEnabled = try c.decodeIfPresent(Bool.self, forKey: .accountMonitorEnabled) ?? false
        self.apiId = try c.decodeIfPresent(String.self, forKey: .apiId) ?? ""
        self.apiHash = try c.decodeIfPresent(String.self, forKey: .apiHash) ?? ""
        self.phone = try c.decodeIfPresent(String.self, forKey: .phone) ?? ""
        self.selectedDialogs = try c.decodeIfPresent([JSONValue].self, forKey: .selectedDialogs)
        self.monitorReplyEnabled = try c.decodeIfPresent(Bool.self, forKey: .monitorReplyEnabled) ?? false
        self.monitorTransferMode = try c.decodeIfPresent(String.self, forKey: .monitorTransferMode) ?? "all"
        self.transferDirMode = try c.decodeIfPresent(String.self, forKey: .transferDirMode) ?? "system"
        self.transferDir = try c.decodeIfPresent(String.self, forKey: .transferDir) ?? ""
        self.notifyTypes = try c.decodeIfPresent(JSONValue.self, forKey: .notifyTypes)
        self.templates = try c.decodeIfPresent(JSONValue.self, forKey: .templates) ?? .object([:])
    }
}

/// TelegramSendCodeRequest
public struct TelegramSendCodeRequest: Codable, Hashable, Sendable {
    public var apiId: String
    public var apiHash: String
    public var phone: String

    public init(apiId: String = "", apiHash: String = "", phone: String = "") {
        self.apiId = apiId
        self.apiHash = apiHash
        self.phone = phone
    }

    enum CodingKeys: String, CodingKey {
        case apiId = "api_id"
        case apiHash = "api_hash"
        case phone
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.apiId = try c.decodeIfPresent(String.self, forKey: .apiId) ?? ""
        self.apiHash = try c.decodeIfPresent(String.self, forKey: .apiHash) ?? ""
        self.phone = try c.decodeIfPresent(String.self, forKey: .phone) ?? ""
    }
}

/// TelegramSignInRequest
public struct TelegramSignInRequest: Codable, Hashable, Sendable {
    public var code: String
    public var password: String

    public init(code: String = "", password: String = "") {
        self.code = code
        self.password = password
    }

    enum CodingKeys: String, CodingKey {
        case code
        case password
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try c.decodeIfPresent(String.self, forKey: .code) ?? ""
        self.password = try c.decodeIfPresent(String.self, forKey: .password) ?? ""
    }
}

/// Test115Payload
public struct Test115Payload: Codable, Hashable, Sendable {
    public var cookie: String

    public init(cookie: String) {
        self.cookie = cookie
    }

    enum CodingKeys: String, CodingKey {
        case cookie
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.cookie = try c.decode(String.self, forKey: .cookie)
    }
}

/// TogglePayload
public struct TogglePayload: Codable, Hashable, Sendable {
    public var enabled: Bool

    public init(enabled: Bool) {
        self.enabled = enabled
    }

    enum CodingKeys: String, CodingKey {
        case enabled
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.enabled = try c.decode(Bool.self, forKey: .enabled)
    }
}

/// ToggleTaskRequest
public struct ToggleTaskRequest: Codable, Hashable, Sendable {
    public var idValue: String
    public var enabled: Bool

    public init(idValue: String, enabled: Bool) {
        self.idValue = idValue
        self.enabled = enabled
    }

    enum CodingKeys: String, CodingKey {
        case idValue = "id"
        case enabled
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.idValue = try c.decode(String.self, forKey: .idValue)
        self.enabled = try c.decode(Bool.self, forKey: .enabled)
    }
}

/// UpdateRssTaskRequest
public struct UpdateRssTaskRequest: Codable, Hashable, Sendable {
    public var idValue: String
    public var name: String
    public var rssUrl: String
    public var cron: String
    public var targetServerIdx: Int
    public var contentType: String
    public var syncLibraryMissingToMp: Bool
    public var enabled: Bool

    public init(idValue: String, name: String, rssUrl: String, cron: String, targetServerIdx: Int = 0, contentType: String = "movies", syncLibraryMissingToMp: Bool = false, enabled: Bool = true) {
        self.idValue = idValue
        self.name = name
        self.rssUrl = rssUrl
        self.cron = cron
        self.targetServerIdx = targetServerIdx
        self.contentType = contentType
        self.syncLibraryMissingToMp = syncLibraryMissingToMp
        self.enabled = enabled
    }

    enum CodingKeys: String, CodingKey {
        case idValue = "id"
        case name
        case rssUrl = "rss_url"
        case cron
        case targetServerIdx = "target_server_idx"
        case contentType = "content_type"
        case syncLibraryMissingToMp = "sync_library_missing_to_mp"
        case enabled
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.idValue = try c.decode(String.self, forKey: .idValue)
        self.name = try c.decode(String.self, forKey: .name)
        self.rssUrl = try c.decode(String.self, forKey: .rssUrl)
        self.cron = try c.decode(String.self, forKey: .cron)
        self.targetServerIdx = try c.decodeIfPresent(Int.self, forKey: .targetServerIdx) ?? 0
        self.contentType = try c.decodeIfPresent(String.self, forKey: .contentType) ?? "movies"
        self.syncLibraryMissingToMp = try c.decodeIfPresent(Bool.self, forKey: .syncLibraryMissingToMp) ?? false
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
    }
}

/// UpdateTaskRequest
public struct UpdateTaskRequest: Codable, Hashable, Sendable {
    public var idValue: String
    public var name: String
    public var cron: String
    public var presetFilename: String
    public var targets: [TaskTarget]
    public var mode: String
    public var enabled: Bool
    public var autoIncludeNewLibraries: Bool

    public init(idValue: String, name: String, cron: String, presetFilename: String, targets: [TaskTarget], mode: String = "random", enabled: Bool = true, autoIncludeNewLibraries: Bool = false) {
        self.idValue = idValue
        self.name = name
        self.cron = cron
        self.presetFilename = presetFilename
        self.targets = targets
        self.mode = mode
        self.enabled = enabled
        self.autoIncludeNewLibraries = autoIncludeNewLibraries
    }

    enum CodingKeys: String, CodingKey {
        case idValue = "id"
        case name
        case cron
        case presetFilename = "preset_filename"
        case targets
        case mode
        case enabled
        case autoIncludeNewLibraries = "auto_include_new_libraries"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.idValue = try c.decode(String.self, forKey: .idValue)
        self.name = try c.decode(String.self, forKey: .name)
        self.cron = try c.decode(String.self, forKey: .cron)
        self.presetFilename = try c.decode(String.self, forKey: .presetFilename)
        self.targets = try c.decode([TaskTarget].self, forKey: .targets)
        self.mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "random"
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        self.autoIncludeNewLibraries = try c.decodeIfPresent(Bool.self, forKey: .autoIncludeNewLibraries) ?? false
    }
}

/// UpgradeCheckRequest
public struct UpgradeCheckRequest: Codable, Hashable, Sendable {
    public var force: Bool

    public init(force: Bool = true) {
        self.force = force
    }

    enum CodingKeys: String, CodingKey {
        case force
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.force = try c.decodeIfPresent(Bool.self, forKey: .force) ?? true
    }
}

/// UpgradeStartRequest
public struct UpgradeStartRequest: Codable, Hashable, Sendable {

    public init() {}
}

/// UploadTaskPayload
public struct UploadTaskPayload: Codable, Hashable, Sendable {
    public var name: String
    public var enabled: Bool
    public var localFolder: String
    public var targetCid: String
    public var targetName: String
    public var targetPath: String
    public var watchMode: String
    public var includeExistingOnStart: Bool
    public var deleteLocalAfterSuccess: Bool
    public var skipUploadWhenNoRapidResource: Bool

    public init(name: String, enabled: Bool = true, localFolder: String, targetCid: String, targetName: String = "", targetPath: String = "", watchMode: String = "realtime", includeExistingOnStart: Bool = true, deleteLocalAfterSuccess: Bool = true, skipUploadWhenNoRapidResource: Bool = false) {
        self.name = name
        self.enabled = enabled
        self.localFolder = localFolder
        self.targetCid = targetCid
        self.targetName = targetName
        self.targetPath = targetPath
        self.watchMode = watchMode
        self.includeExistingOnStart = includeExistingOnStart
        self.deleteLocalAfterSuccess = deleteLocalAfterSuccess
        self.skipUploadWhenNoRapidResource = skipUploadWhenNoRapidResource
    }

    enum CodingKeys: String, CodingKey {
        case name
        case enabled
        case localFolder = "local_folder"
        case targetCid = "target_cid"
        case targetName = "target_name"
        case targetPath = "target_path"
        case watchMode = "watch_mode"
        case includeExistingOnStart = "include_existing_on_start"
        case deleteLocalAfterSuccess = "delete_local_after_success"
        case skipUploadWhenNoRapidResource = "skip_upload_when_no_rapid_resource"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try c.decode(String.self, forKey: .name)
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        self.localFolder = try c.decode(String.self, forKey: .localFolder)
        self.targetCid = try c.decode(String.self, forKey: .targetCid)
        self.targetName = try c.decodeIfPresent(String.self, forKey: .targetName) ?? ""
        self.targetPath = try c.decodeIfPresent(String.self, forKey: .targetPath) ?? ""
        self.watchMode = try c.decodeIfPresent(String.self, forKey: .watchMode) ?? "realtime"
        self.includeExistingOnStart = try c.decodeIfPresent(Bool.self, forKey: .includeExistingOnStart) ?? true
        self.deleteLocalAfterSuccess = try c.decodeIfPresent(Bool.self, forKey: .deleteLocalAfterSuccess) ?? true
        self.skipUploadWhenNoRapidResource = try c.decodeIfPresent(Bool.self, forKey: .skipUploadWhenNoRapidResource) ?? false
    }
}

/// UploadThreadSettingsPayload
public struct UploadThreadSettingsPayload: Codable, Hashable, Sendable {
    public var verifyConcurrency: Int
    public var rapidConcurrency: Int
    public var uploadConcurrency: Int

    public init(verifyConcurrency: Int = 5, rapidConcurrency: Int = 5, uploadConcurrency: Int = 5) {
        self.verifyConcurrency = verifyConcurrency
        self.rapidConcurrency = rapidConcurrency
        self.uploadConcurrency = uploadConcurrency
    }

    enum CodingKeys: String, CodingKey {
        case verifyConcurrency = "verify_concurrency"
        case rapidConcurrency = "rapid_concurrency"
        case uploadConcurrency = "upload_concurrency"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.verifyConcurrency = try c.decodeIfPresent(Int.self, forKey: .verifyConcurrency) ?? 5
        self.rapidConcurrency = try c.decodeIfPresent(Int.self, forKey: .rapidConcurrency) ?? 5
        self.uploadConcurrency = try c.decodeIfPresent(Int.self, forKey: .uploadConcurrency) ?? 5
    }
}

/// ValidationError
public struct ValidationError: Codable, Hashable, Sendable {
    public var loc: [JSONValue]
    public var msg: String
    public var typeValue: String
    public var input: JSONValue?
    public var ctx: JSONValue?

    public init(loc: [JSONValue], msg: String, typeValue: String, input: JSONValue? = nil, ctx: JSONValue? = nil) {
        self.loc = loc
        self.msg = msg
        self.typeValue = typeValue
        self.input = input
        self.ctx = ctx
    }

    enum CodingKeys: String, CodingKey {
        case loc
        case msg
        case typeValue = "type"
        case input
        case ctx
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.loc = try c.decode([JSONValue].self, forKey: .loc)
        self.msg = try c.decode(String.self, forKey: .msg)
        self.typeValue = try c.decode(String.self, forKey: .typeValue)
        self.input = try c.decodeIfPresent(JSONValue.self, forKey: .input)
        self.ctx = try c.decodeIfPresent(JSONValue.self, forKey: .ctx)
    }
}

/// WebhookConfigModel
public struct WebhookConfigModel: Codable, Hashable, Sendable {
    public var enabled: Bool
    public var engine: String
    public var preset: String
    public var mode: String
    public var deleteSyncEnabled: Bool

    public init(enabled: Bool = false, engine: String = "classic", preset: String = "", mode: String = "random", deleteSyncEnabled: Bool = true) {
        self.enabled = enabled
        self.engine = engine
        self.preset = preset
        self.mode = mode
        self.deleteSyncEnabled = deleteSyncEnabled
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case engine
        case preset
        case mode
        case deleteSyncEnabled = "delete_sync_enabled"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        self.engine = try c.decodeIfPresent(String.self, forKey: .engine) ?? "classic"
        self.preset = try c.decodeIfPresent(String.self, forKey: .preset) ?? ""
        self.mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "random"
        self.deleteSyncEnabled = try c.decodeIfPresent(Bool.self, forKey: .deleteSyncEnabled) ?? true
    }
}

/// WechatNotifyConfigModel
public struct WechatNotifyConfigModel: Codable, Hashable, Sendable {
    public var enabled: Bool
    public var name: String
    public var channelName: String
    public var corpId: String
    public var appSecret: String
    public var token: String
    public var agentId: String
    public var proxyUrl: String
    public var encodingAesKey: String
    public var adminWhitelist: String
    public var notifyTypes: JSONValue?
    public var templates: JSONValue

    public init(enabled: Bool = false, name: String = "微信", channelName: String = "", corpId: String = "", appSecret: String = "", token: String = "", agentId: String = "", proxyUrl: String = "", encodingAesKey: String = "", adminWhitelist: String = "", notifyTypes: JSONValue? = nil, templates: JSONValue = .object([:])) {
        self.enabled = enabled
        self.name = name
        self.channelName = channelName
        self.corpId = corpId
        self.appSecret = appSecret
        self.token = token
        self.agentId = agentId
        self.proxyUrl = proxyUrl
        self.encodingAesKey = encodingAesKey
        self.adminWhitelist = adminWhitelist
        self.notifyTypes = notifyTypes
        self.templates = templates
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case name
        case channelName = "channel_name"
        case corpId = "corp_id"
        case appSecret = "app_secret"
        case token
        case agentId = "agent_id"
        case proxyUrl = "proxy_url"
        case encodingAesKey = "encoding_aes_key"
        case adminWhitelist = "admin_whitelist"
        case notifyTypes = "notify_types"
        case templates
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? "微信"
        self.channelName = try c.decodeIfPresent(String.self, forKey: .channelName) ?? ""
        self.corpId = try c.decodeIfPresent(String.self, forKey: .corpId) ?? ""
        self.appSecret = try c.decodeIfPresent(String.self, forKey: .appSecret) ?? ""
        self.token = try c.decodeIfPresent(String.self, forKey: .token) ?? ""
        self.agentId = try c.decodeIfPresent(String.self, forKey: .agentId) ?? ""
        self.proxyUrl = try c.decodeIfPresent(String.self, forKey: .proxyUrl) ?? ""
        self.encodingAesKey = try c.decodeIfPresent(String.self, forKey: .encodingAesKey) ?? ""
        self.adminWhitelist = try c.decodeIfPresent(String.self, forKey: .adminWhitelist) ?? ""
        self.notifyTypes = try c.decodeIfPresent(JSONValue.self, forKey: .notifyTypes)
        self.templates = try c.decodeIfPresent(JSONValue.self, forKey: .templates) ?? .object([:])
    }
}
