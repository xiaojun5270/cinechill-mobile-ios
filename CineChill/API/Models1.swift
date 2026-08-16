// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// AIAssistantGlobalProfilePayload
public struct AIAssistantGlobalProfilePayload: Codable, Hashable, Sendable {
    public var robotPrompt: String
    public var userPrompt: String
    public var notesPrompt: String

    public init(robotPrompt: String = "", userPrompt: String = "", notesPrompt: String = "") {
        self.robotPrompt = robotPrompt
        self.userPrompt = userPrompt
        self.notesPrompt = notesPrompt
    }

    enum CodingKeys: String, CodingKey {
        case robotPrompt = "robot_prompt"
        case userPrompt = "user_prompt"
        case notesPrompt = "notes_prompt"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.robotPrompt = try c.decodeIfPresent(String.self, forKey: .robotPrompt) ?? ""
        self.userPrompt = try c.decodeIfPresent(String.self, forKey: .userPrompt) ?? ""
        self.notesPrompt = try c.decodeIfPresent(String.self, forKey: .notesPrompt) ?? ""
    }
}

/// AIEpisodeResolverConfigPayload
public struct AIEpisodeResolverConfigPayload: Codable, Hashable, Sendable {
    public var enabled: Bool
    public var proxyEnabled: Bool
    public var mediaIdentityEnabled: Bool
    public var tmdbEpisodeVerifyEnabled: Bool
    public var assistantToolsEnabled: Bool
    public var assistantContextCompressionEnabled: Bool
    public var assistantContextCompressionThreshold: Double
    public var assistantContextTargetRatio: Double
    public var assistantContextProtectRecent: Int
    public var assistantContextProtectHead: Int
    public var modelContextLength: Int
    public var baseUrl: String
    public var apiKey: String
    public var model: String

    public init(enabled: Bool = false, proxyEnabled: Bool = false, mediaIdentityEnabled: Bool = true, tmdbEpisodeVerifyEnabled: Bool = true, assistantToolsEnabled: Bool = false, assistantContextCompressionEnabled: Bool = true, assistantContextCompressionThreshold: Double = 0.5, assistantContextTargetRatio: Double = 0.2, assistantContextProtectRecent: Int = 20, assistantContextProtectHead: Int = 3, modelContextLength: Int = 0, baseUrl: String = "", apiKey: String = "", model: String = "") {
        self.enabled = enabled
        self.proxyEnabled = proxyEnabled
        self.mediaIdentityEnabled = mediaIdentityEnabled
        self.tmdbEpisodeVerifyEnabled = tmdbEpisodeVerifyEnabled
        self.assistantToolsEnabled = assistantToolsEnabled
        self.assistantContextCompressionEnabled = assistantContextCompressionEnabled
        self.assistantContextCompressionThreshold = assistantContextCompressionThreshold
        self.assistantContextTargetRatio = assistantContextTargetRatio
        self.assistantContextProtectRecent = assistantContextProtectRecent
        self.assistantContextProtectHead = assistantContextProtectHead
        self.modelContextLength = modelContextLength
        self.baseUrl = baseUrl
        self.apiKey = apiKey
        self.model = model
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case proxyEnabled = "proxy_enabled"
        case mediaIdentityEnabled = "media_identity_enabled"
        case tmdbEpisodeVerifyEnabled = "tmdb_episode_verify_enabled"
        case assistantToolsEnabled = "assistant_tools_enabled"
        case assistantContextCompressionEnabled = "assistant_context_compression_enabled"
        case assistantContextCompressionThreshold = "assistant_context_compression_threshold"
        case assistantContextTargetRatio = "assistant_context_target_ratio"
        case assistantContextProtectRecent = "assistant_context_protect_recent"
        case assistantContextProtectHead = "assistant_context_protect_head"
        case modelContextLength = "model_context_length"
        case baseUrl = "base_url"
        case apiKey = "api_key"
        case model
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        self.proxyEnabled = try c.decodeIfPresent(Bool.self, forKey: .proxyEnabled) ?? false
        self.mediaIdentityEnabled = try c.decodeIfPresent(Bool.self, forKey: .mediaIdentityEnabled) ?? true
        self.tmdbEpisodeVerifyEnabled = try c.decodeIfPresent(Bool.self, forKey: .tmdbEpisodeVerifyEnabled) ?? true
        self.assistantToolsEnabled = try c.decodeIfPresent(Bool.self, forKey: .assistantToolsEnabled) ?? false
        self.assistantContextCompressionEnabled = try c.decodeIfPresent(Bool.self, forKey: .assistantContextCompressionEnabled) ?? true
        self.assistantContextCompressionThreshold = try c.decodeIfPresent(Double.self, forKey: .assistantContextCompressionThreshold) ?? 0.5
        self.assistantContextTargetRatio = try c.decodeIfPresent(Double.self, forKey: .assistantContextTargetRatio) ?? 0.2
        self.assistantContextProtectRecent = try c.decodeIfPresent(Int.self, forKey: .assistantContextProtectRecent) ?? 20
        self.assistantContextProtectHead = try c.decodeIfPresent(Int.self, forKey: .assistantContextProtectHead) ?? 3
        self.modelContextLength = try c.decodeIfPresent(Int.self, forKey: .modelContextLength) ?? 0
        self.baseUrl = try c.decodeIfPresent(String.self, forKey: .baseUrl) ?? ""
        self.apiKey = try c.decodeIfPresent(String.self, forKey: .apiKey) ?? ""
        self.model = try c.decodeIfPresent(String.self, forKey: .model) ?? ""
    }
}

/// AutoUpdatePayload
public struct AutoUpdatePayload: Codable, Hashable, Sendable {
    public var enabled: Bool
    public var image: String

    public init(enabled: Bool = false, image: String = "") {
        self.enabled = enabled
        self.image = image
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case image
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        self.image = try c.decodeIfPresent(String.self, forKey: .image) ?? ""
    }
}

/// Body_upload_emby_user_avatar_api_emby_users__user_id__avatar_post
public struct Body_upload_emby_user_avatar_api_emby_users__user_id__avatar_post: Codable, Hashable, Sendable {
    public var file: String

    public init(file: String) {
        self.file = file
    }

    enum CodingKeys: String, CodingKey {
        case file
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.file = try c.decode(String.self, forKey: .file)
    }
}

/// Body_upload_font_api_upload_font_post
public struct Body_upload_font_api_upload_font_post: Codable, Hashable, Sendable {
    public var file: String

    public init(file: String) {
        self.file = file
    }

    enum CodingKeys: String, CodingKey {
        case file
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.file = try c.decode(String.self, forKey: .file)
    }
}

/// Browse115Payload
public struct Browse115Payload: Codable, Hashable, Sendable {
    public var cid: String

    public init(cid: String = "0") {
        self.cid = cid
    }

    enum CodingKeys: String, CodingKey {
        case cid
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.cid = try c.decodeIfPresent(String.self, forKey: .cid) ?? "0"
    }
}

/// CategoryRulesPayload
public struct CategoryRulesPayload: Codable, Hashable, Sendable {
    public var movie: [JSONValue]
    public var tv: [JSONValue]

    public init(movie: [JSONValue] = [], tv: [JSONValue] = []) {
        self.movie = movie
        self.tv = tv
    }

    enum CodingKeys: String, CodingKey {
        case movie
        case tv
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.movie = try c.decodeIfPresent([JSONValue].self, forKey: .movie) ?? []
        self.tv = try c.decodeIfPresent([JSONValue].self, forKey: .tv) ?? []
    }
}

/// ChangeAuthRequest
public struct ChangeAuthRequest: Codable, Hashable, Sendable {
    public var oldPassword: String
    public var newUsername: String
    public var newPassword: String

    public init(oldPassword: String, newUsername: String, newPassword: String) {
        self.oldPassword = oldPassword
        self.newUsername = newUsername
        self.newPassword = newPassword
    }

    enum CodingKeys: String, CodingKey {
        case oldPassword = "old_password"
        case newUsername = "new_username"
        case newPassword = "new_password"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.oldPassword = try c.decode(String.self, forKey: .oldPassword)
        self.newUsername = try c.decode(String.self, forKey: .newUsername)
        self.newPassword = try c.decode(String.self, forKey: .newPassword)
    }
}

/// CheckUpdatesPayload
public struct CheckUpdatesPayload: Codable, Hashable, Sendable {
    public var images: [JSONValue]

    public init(images: [JSONValue] = []) {
        self.images = images
    }

    enum CodingKeys: String, CodingKey {
        case images
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.images = try c.decodeIfPresent([JSONValue].self, forKey: .images) ?? []
    }
}

/// CleanupFolder
public struct CleanupFolder: Codable, Hashable, Sendable {
    public var cid: String
    public var name: String
    public var path: String

    public init(cid: String, name: String = "", path: String = "") {
        self.cid = cid
        self.name = name
        self.path = path
    }

    enum CodingKeys: String, CodingKey {
        case cid
        case name
        case path
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.cid = try c.decode(String.self, forKey: .cid)
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.path = try c.decodeIfPresent(String.self, forKey: .path) ?? ""
    }
}

/// CleanupTaskPayload
public struct CleanupTaskPayload: Codable, Hashable, Sendable {
    public var name: String
    public var cron: String
    public var enabled: Bool
    public var clearRecycleBin: Bool
    public var folders: [CleanupFolder]

    public init(name: String, cron: String, enabled: Bool = true, clearRecycleBin: Bool = true, folders: [CleanupFolder]) {
        self.name = name
        self.cron = cron
        self.enabled = enabled
        self.clearRecycleBin = clearRecycleBin
        self.folders = folders
    }

    enum CodingKeys: String, CodingKey {
        case name
        case cron
        case enabled
        case clearRecycleBin = "clear_recycle_bin"
        case folders
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try c.decode(String.self, forKey: .name)
        self.cron = try c.decode(String.self, forKey: .cron)
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        self.clearRecycleBin = try c.decodeIfPresent(Bool.self, forKey: .clearRecycleBin) ?? true
        self.folders = try c.decode([CleanupFolder].self, forKey: .folders)
    }
}

/// ClearOrganizeHistoryPayload
public struct ClearOrganizeHistoryPayload: Codable, Hashable, Sendable {
    public var categories: [String]?

    public init(categories: [String]? = nil) {
        self.categories = categories
    }

    enum CodingKeys: String, CodingKey {
        case categories
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.categories = try c.decodeIfPresent([String].self, forKey: .categories)
    }
}

/// CloudBrowsePayload
public struct CloudBrowsePayload: Codable, Hashable, Sendable {
    public var cookie: String
    public var cid: String
    public var includeFiles: Bool

    public init(cookie: String, cid: String = "0", includeFiles: Bool = true) {
        self.cookie = cookie
        self.cid = cid
        self.includeFiles = includeFiles
    }

    enum CodingKeys: String, CodingKey {
        case cookie
        case cid
        case includeFiles = "include_files"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.cookie = try c.decode(String.self, forKey: .cookie)
        self.cid = try c.decodeIfPresent(String.self, forKey: .cid) ?? "0"
        self.includeFiles = try c.decodeIfPresent(Bool.self, forKey: .includeFiles) ?? true
    }
}

/// CloudRapidPayload
public struct CloudRapidPayload: Codable, Hashable, Sendable {
    public var sourceCookie: String
    public var targetCookie: String
    public var targetCid: String
    public var targetPath: String
    public var concurrency: Int
    public var items: [JSONValue]

    public init(sourceCookie: String, targetCookie: String, targetCid: String, targetPath: String = "", concurrency: Int = 4, items: [JSONValue]) {
        self.sourceCookie = sourceCookie
        self.targetCookie = targetCookie
        self.targetCid = targetCid
        self.targetPath = targetPath
        self.concurrency = concurrency
        self.items = items
    }

    enum CodingKeys: String, CodingKey {
        case sourceCookie = "source_cookie"
        case targetCookie = "target_cookie"
        case targetCid = "target_cid"
        case targetPath = "target_path"
        case concurrency
        case items
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.sourceCookie = try c.decode(String.self, forKey: .sourceCookie)
        self.targetCookie = try c.decode(String.self, forKey: .targetCookie)
        self.targetCid = try c.decode(String.self, forKey: .targetCid)
        self.targetPath = try c.decodeIfPresent(String.self, forKey: .targetPath) ?? ""
        self.concurrency = try c.decodeIfPresent(Int.self, forKey: .concurrency) ?? 4
        self.items = try c.decode([JSONValue].self, forKey: .items)
    }
}

/// ComposeImagePayload
public struct ComposeImagePayload: Codable, Hashable, Sendable {
    public var image: String

    public init(image: String) {
        self.image = image
    }

    enum CodingKeys: String, CodingKey {
        case image
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.image = try c.decode(String.self, forKey: .image)
    }
}

/// Config302Payload
public struct Config302Payload: Codable, Hashable, Sendable {
    public var drives: [Drive115Config]
    public var embys: [Emby302Config]

    public init(drives: [Drive115Config] = [], embys: [Emby302Config] = []) {
        self.drives = drives
        self.embys = embys
    }

    enum CodingKeys: String, CodingKey {
        case drives
        case embys
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.drives = try c.decodeIfPresent([Drive115Config].self, forKey: .drives) ?? []
        self.embys = try c.decodeIfPresent([Emby302Config].self, forKey: .embys) ?? []
    }
}

/// ConnectionRequest
public struct ConnectionRequest: Codable, Hashable, Sendable {
    public var url: String
    public var key: String
    public var publicHost: String?

    public init(url: String, key: String, publicHost: String? = nil) {
        self.url = url
        self.key = key
        self.publicHost = publicHost
    }

    enum CodingKeys: String, CodingKey {
        case url
        case key
        case publicHost = "public_host"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try c.decode(String.self, forKey: .url)
        self.key = try c.decode(String.self, forKey: .key)
        self.publicHost = try c.decodeIfPresent(String.self, forKey: .publicHost)
    }
}

/// ContainerActionPayload
public struct ContainerActionPayload: Codable, Hashable, Sendable {
    public var action: String
    public var force: Bool
    public var image: String

    public init(action: String = "restart", force: Bool = false, image: String = "") {
        self.action = action
        self.force = force
        self.image = image
    }

    enum CodingKeys: String, CodingKey {
        case action
        case force
        case image
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.action = try c.decodeIfPresent(String.self, forKey: .action) ?? "restart"
        self.force = try c.decodeIfPresent(Bool.self, forKey: .force) ?? false
        self.image = try c.decodeIfPresent(String.self, forKey: .image) ?? ""
    }
}

/// CreateTaskRequest
public struct CreateTaskRequest: Codable, Hashable, Sendable {
    public var name: String
    public var cron: String
    public var presetFilename: String
    public var targets: [TaskTarget]
    public var mode: String
    public var enabled: Bool
    public var autoIncludeNewLibraries: Bool

    public init(name: String, cron: String, presetFilename: String, targets: [TaskTarget], mode: String = "random", enabled: Bool = true, autoIncludeNewLibraries: Bool = false) {
        self.name = name
        self.cron = cron
        self.presetFilename = presetFilename
        self.targets = targets
        self.mode = mode
        self.enabled = enabled
        self.autoIncludeNewLibraries = autoIncludeNewLibraries
    }

    enum CodingKeys: String, CodingKey {
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
        self.name = try c.decode(String.self, forKey: .name)
        self.cron = try c.decode(String.self, forKey: .cron)
        self.presetFilename = try c.decode(String.self, forKey: .presetFilename)
        self.targets = try c.decode([TaskTarget].self, forKey: .targets)
        self.mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "random"
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        self.autoIncludeNewLibraries = try c.decodeIfPresent(Bool.self, forKey: .autoIncludeNewLibraries) ?? false
    }
}

/// DeleteOrganizeHistoryPayload
public struct DeleteOrganizeHistoryPayload: Codable, Hashable, Sendable {
    public var ids: [String]?

    public init(ids: [String]? = nil) {
        self.ids = ids
    }

    enum CodingKeys: String, CodingKey {
        case ids
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.ids = try c.decodeIfPresent([String].self, forKey: .ids)
    }
}

/// Drive115Config
public struct Drive115Config: Codable, Hashable, Sendable {
    public var name: String
    public var cookie: String
    public var showCookie: Bool
    public var enableSync: Bool
    public var autoDelete: Bool
    public var deleteCron: String
    public var recycleCode: String
    public var uploadDir: String
    public var enableStandardTopology: Bool
    public var localMediaRoot: String
    public var remoteRootName: String
    public var transferDir: String
    public var transferDriveIndex: Int

    public init(name: String = "115", cookie: String = "", showCookie: Bool = false, enableSync: Bool = false, autoDelete: Bool = true, deleteCron: String = "30 3 * * *", recycleCode: String = "", uploadDir: String = "/CineChill", enableStandardTopology: Bool = true, localMediaRoot: String = "", remoteRootName: String = "影视库", transferDir: String = "", transferDriveIndex: Int = 0) {
        self.name = name
        self.cookie = cookie
        self.showCookie = showCookie
        self.enableSync = enableSync
        self.autoDelete = autoDelete
        self.deleteCron = deleteCron
        self.recycleCode = recycleCode
        self.uploadDir = uploadDir
        self.enableStandardTopology = enableStandardTopology
        self.localMediaRoot = localMediaRoot
        self.remoteRootName = remoteRootName
        self.transferDir = transferDir
        self.transferDriveIndex = transferDriveIndex
    }

    enum CodingKeys: String, CodingKey {
        case name
        case cookie
        case showCookie = "show_cookie"
        case enableSync = "enable_sync"
        case autoDelete = "auto_delete"
        case deleteCron = "delete_cron"
        case recycleCode = "recycle_code"
        case uploadDir = "upload_dir"
        case enableStandardTopology = "enable_standard_topology"
        case localMediaRoot = "local_media_root"
        case remoteRootName = "remote_root_name"
        case transferDir = "transfer_dir"
        case transferDriveIndex = "transfer_drive_index"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? "115"
        self.cookie = try c.decodeIfPresent(String.self, forKey: .cookie) ?? ""
        self.showCookie = try c.decodeIfPresent(Bool.self, forKey: .showCookie) ?? false
        self.enableSync = try c.decodeIfPresent(Bool.self, forKey: .enableSync) ?? false
        self.autoDelete = try c.decodeIfPresent(Bool.self, forKey: .autoDelete) ?? true
        self.deleteCron = try c.decodeIfPresent(String.self, forKey: .deleteCron) ?? "30 3 * * *"
        self.recycleCode = try c.decodeIfPresent(String.self, forKey: .recycleCode) ?? ""
        self.uploadDir = try c.decodeIfPresent(String.self, forKey: .uploadDir) ?? "/CineChill"
        self.enableStandardTopology = try c.decodeIfPresent(Bool.self, forKey: .enableStandardTopology) ?? true
        self.localMediaRoot = try c.decodeIfPresent(String.self, forKey: .localMediaRoot) ?? ""
        self.remoteRootName = try c.decodeIfPresent(String.self, forKey: .remoteRootName) ?? "影视库"
        self.transferDir = try c.decodeIfPresent(String.self, forKey: .transferDir) ?? ""
        self.transferDriveIndex = try c.decodeIfPresent(Int.self, forKey: .transferDriveIndex) ?? 0
    }
}

/// Emby302Config
public struct Emby302Config: Codable, Hashable, Sendable {
    public var name: String
    public var url: String
    public var key: String
    public var publicHost: String
    public var proxyPort: String
    public var modes: Emby302Modes?
    public var preload: Bool
    public var enabled: Bool
    public var driveIndex: Int

    public init(name: String = "Emby", url: String = "", key: String = "", publicHost: String = "", proxyPort: String = "8011", modes: Emby302Modes? = nil, preload: Bool = false, enabled: Bool = true, driveIndex: Int = -1) {
        self.name = name
        self.url = url
        self.key = key
        self.publicHost = publicHost
        self.proxyPort = proxyPort
        self.modes = modes
        self.preload = preload
        self.enabled = enabled
        self.driveIndex = driveIndex
    }

    enum CodingKeys: String, CodingKey {
        case name
        case url
        case key
        case publicHost = "public_host"
        case proxyPort = "proxy_port"
        case modes
        case preload
        case enabled
        case driveIndex = "drive_index"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Emby"
        self.url = try c.decodeIfPresent(String.self, forKey: .url) ?? ""
        self.key = try c.decodeIfPresent(String.self, forKey: .key) ?? ""
        self.publicHost = try c.decodeIfPresent(String.self, forKey: .publicHost) ?? ""
        self.proxyPort = try c.decodeIfPresent(String.self, forKey: .proxyPort) ?? "8011"
        self.modes = try c.decodeIfPresent(Emby302Modes.self, forKey: .modes)
        self.preload = try c.decodeIfPresent(Bool.self, forKey: .preload) ?? false
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        self.driveIndex = try c.decodeIfPresent(Int.self, forKey: .driveIndex) ?? -1
    }
}

/// Emby302Modes
public struct Emby302Modes: Codable, Hashable, Sendable {
    public var pickcode: Bool

    public init(pickcode: Bool = true) {
        self.pickcode = pickcode
    }

    enum CodingKeys: String, CodingKey {
        case pickcode
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.pickcode = try c.decodeIfPresent(Bool.self, forKey: .pickcode) ?? true
    }
}

/// EmbyItemImagesRequest
public struct EmbyItemImagesRequest: Codable, Hashable, Sendable {
    public var url: String
    public var key: String
    public var publicHost: String?
    public var itemId: String
    public var typeValue: String

    public init(url: String, key: String, publicHost: String? = nil, itemId: String, typeValue: String = "Backdrop") {
        self.url = url
        self.key = key
        self.publicHost = publicHost
        self.itemId = itemId
        self.typeValue = typeValue
    }

    enum CodingKeys: String, CodingKey {
        case url
        case key
        case publicHost = "public_host"
        case itemId = "item_id"
        case typeValue = "type"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try c.decode(String.self, forKey: .url)
        self.key = try c.decode(String.self, forKey: .key)
        self.publicHost = try c.decodeIfPresent(String.self, forKey: .publicHost)
        self.itemId = try c.decode(String.self, forKey: .itemId)
        self.typeValue = try c.decodeIfPresent(String.self, forKey: .typeValue) ?? "Backdrop"
    }
}

/// EmbyLibraryLocaleFixPayload
public struct EmbyLibraryLocaleFixPayload: Codable, Hashable, Sendable {
    public var serverIdx: Int
    public var overwrite: Bool
    public var refreshCache: Bool
    public var onceOnly: Bool

    public init(serverIdx: Int = 0, overwrite: Bool = false, refreshCache: Bool = true, onceOnly: Bool = true) {
        self.serverIdx = serverIdx
        self.overwrite = overwrite
        self.refreshCache = refreshCache
        self.onceOnly = onceOnly
    }

    enum CodingKeys: String, CodingKey {
        case serverIdx = "server_idx"
        case overwrite
        case refreshCache = "refresh_cache"
        case onceOnly = "once_only"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.serverIdx = try c.decodeIfPresent(Int.self, forKey: .serverIdx) ?? 0
        self.overwrite = try c.decodeIfPresent(Bool.self, forKey: .overwrite) ?? false
        self.refreshCache = try c.decodeIfPresent(Bool.self, forKey: .refreshCache) ?? true
        self.onceOnly = try c.decodeIfPresent(Bool.self, forKey: .onceOnly) ?? true
    }
}

/// EmbyLibraryScraperSyncPayload
public struct EmbyLibraryScraperSyncPayload: Codable, Hashable, Sendable {
    public var serverIdx: Int
    public var enabled: Bool
    public var refreshCache: Bool

    public init(serverIdx: Int = 0, enabled: Bool = false, refreshCache: Bool = true) {
        self.serverIdx = serverIdx
        self.enabled = enabled
        self.refreshCache = refreshCache
    }

    enum CodingKeys: String, CodingKey {
        case serverIdx = "server_idx"
        case enabled
        case refreshCache = "refresh_cache"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.serverIdx = try c.decodeIfPresent(Int.self, forKey: .serverIdx) ?? 0
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        self.refreshCache = try c.decodeIfPresent(Bool.self, forKey: .refreshCache) ?? true
    }
}

/// EmbyRandomPoolRequest
public struct EmbyRandomPoolRequest: Codable, Hashable, Sendable {
    public var url: String
    public var key: String
    public var publicHost: String?
    public var libraryId: String
    public var typeValue: String
    public var limit: Int

    public init(url: String, key: String, publicHost: String? = nil, libraryId: String, typeValue: String = "Backdrop", limit: Int = 50) {
        self.url = url
        self.key = key
        self.publicHost = publicHost
        self.libraryId = libraryId
        self.typeValue = typeValue
        self.limit = limit
    }

    enum CodingKeys: String, CodingKey {
        case url
        case key
        case publicHost = "public_host"
        case libraryId = "library_id"
        case typeValue = "type"
        case limit
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try c.decode(String.self, forKey: .url)
        self.key = try c.decode(String.self, forKey: .key)
        self.publicHost = try c.decodeIfPresent(String.self, forKey: .publicHost)
        self.libraryId = try c.decode(String.self, forKey: .libraryId)
        self.typeValue = try c.decodeIfPresent(String.self, forKey: .typeValue) ?? "Backdrop"
        self.limit = try c.decodeIfPresent(Int.self, forKey: .limit) ?? 50
    }
}

/// EmbySearchRequest
public struct EmbySearchRequest: Codable, Hashable, Sendable {
    public var url: String
    public var key: String
    public var publicHost: String?
    public var query: String
    public var libraryId: String?
    public var typeValue: String

    public init(url: String, key: String, publicHost: String? = nil, query: String, libraryId: String? = nil, typeValue: String = "Primary") {
        self.url = url
        self.key = key
        self.publicHost = publicHost
        self.query = query
        self.libraryId = libraryId
        self.typeValue = typeValue
    }

    enum CodingKeys: String, CodingKey {
        case url
        case key
        case publicHost = "public_host"
        case query
        case libraryId = "library_id"
        case typeValue = "type"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try c.decode(String.self, forKey: .url)
        self.key = try c.decode(String.self, forKey: .key)
        self.publicHost = try c.decodeIfPresent(String.self, forKey: .publicHost)
        self.query = try c.decode(String.self, forKey: .query)
        self.libraryId = try c.decodeIfPresent(String.self, forKey: .libraryId)
        self.typeValue = try c.decodeIfPresent(String.self, forKey: .typeValue) ?? "Primary"
    }
}

/// EmbyTaskTriggersPayload
public struct EmbyTaskTriggersPayload: Codable, Hashable, Sendable {
    public var triggers: [JSONValue]?

    public init(triggers: [JSONValue]? = nil) {
        self.triggers = triggers
    }

    enum CodingKeys: String, CodingKey {
        case triggers
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.triggers = try c.decodeIfPresent([JSONValue].self, forKey: .triggers)
    }
}

/// EmbyUserCreatePayload
public struct EmbyUserCreatePayload: Codable, Hashable, Sendable {
    public var name: String
    public var templateUserId: String
    public var password: String

    public init(name: String, templateUserId: String = "", password: String = "") {
        self.name = name
        self.templateUserId = templateUserId
        self.password = password
    }

    enum CodingKeys: String, CodingKey {
        case name
        case templateUserId = "template_user_id"
        case password
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try c.decode(String.self, forKey: .name)
        self.templateUserId = try c.decodeIfPresent(String.self, forKey: .templateUserId) ?? ""
        self.password = try c.decodeIfPresent(String.self, forKey: .password) ?? ""
    }
}

/// EmbyUserDisabledPayload
public struct EmbyUserDisabledPayload: Codable, Hashable, Sendable {
    public var disabled: Bool

    public init(disabled: Bool = true) {
        self.disabled = disabled
    }

    enum CodingKeys: String, CodingKey {
        case disabled
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.disabled = try c.decodeIfPresent(Bool.self, forKey: .disabled) ?? true
    }
}

/// EmbyUserPasswordPayload
public struct EmbyUserPasswordPayload: Codable, Hashable, Sendable {
    public var newPassword: String
    public var currentPassword: String
    public var resetPassword: Bool

    public init(newPassword: String, currentPassword: String = "", resetPassword: Bool = true) {
        self.newPassword = newPassword
        self.currentPassword = currentPassword
        self.resetPassword = resetPassword
    }

    enum CodingKeys: String, CodingKey {
        case newPassword = "new_password"
        case currentPassword = "current_password"
        case resetPassword = "reset_password"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.newPassword = try c.decode(String.self, forKey: .newPassword)
        self.currentPassword = try c.decodeIfPresent(String.self, forKey: .currentPassword) ?? ""
        self.resetPassword = try c.decodeIfPresent(Bool.self, forKey: .resetPassword) ?? true
    }
}

/// EmbyUserUpdatePayload
public struct EmbyUserUpdatePayload: Codable, Hashable, Sendable {
    public var name: String?
    public var policy: JSONValue?
    public var configuration: JSONValue?

    public init(name: String? = nil, policy: JSONValue? = nil, configuration: JSONValue? = nil) {
        self.name = name
        self.policy = policy
        self.configuration = configuration
    }

    enum CodingKeys: String, CodingKey {
        case name
        case policy
        case configuration
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try c.decodeIfPresent(String.self, forKey: .name)
        self.policy = try c.decodeIfPresent(JSONValue.self, forKey: .policy)
        self.configuration = try c.decodeIfPresent(JSONValue.self, forKey: .configuration)
    }
}

/// FnosSignConfigPayload
public struct FnosSignConfigPayload: Codable, Hashable, Sendable {
    public var enabled: Bool
    public var notify: Bool
    public var cookie: String
    public var cron: String
    public var maxRetries: Int
    public var retryInterval: Int
    public var historyDays: Int

    public init(enabled: Bool = false, notify: Bool = true, cookie: String = "", cron: String = "0 8 * * *", maxRetries: Int = 3, retryInterval: Int = 30, historyDays: Int = 30) {
        self.enabled = enabled
        self.notify = notify
        self.cookie = cookie
        self.cron = cron
        self.maxRetries = maxRetries
        self.retryInterval = retryInterval
        self.historyDays = historyDays
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case notify
        case cookie
        case cron
        case maxRetries = "max_retries"
        case retryInterval = "retry_interval"
        case historyDays = "history_days"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        self.notify = try c.decodeIfPresent(Bool.self, forKey: .notify) ?? true
        self.cookie = try c.decodeIfPresent(String.self, forKey: .cookie) ?? ""
        self.cron = try c.decodeIfPresent(String.self, forKey: .cron) ?? "0 8 * * *"
        self.maxRetries = try c.decodeIfPresent(Int.self, forKey: .maxRetries) ?? 3
        self.retryInterval = try c.decodeIfPresent(Int.self, forKey: .retryInterval) ?? 30
        self.historyDays = try c.decodeIfPresent(Int.self, forKey: .historyDays) ?? 30
    }
}
