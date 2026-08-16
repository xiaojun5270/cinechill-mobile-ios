// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// FnosSignCookiePayload
public struct FnosSignCookiePayload: Codable, Hashable, Sendable {
    public var cookie: String?

    public init(cookie: String? = nil) {
        self.cookie = cookie
    }

    enum CodingKeys: String, CodingKey {
        case cookie
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.cookie = try c.decodeIfPresent(String.self, forKey: .cookie)
    }
}

/// FnosSignRunPayload
public struct FnosSignRunPayload: Codable, Hashable, Sendable {
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

/// ForwardConfigRequest
public struct ForwardConfigRequest: Codable, Hashable, Sendable {
    public var enabled: Bool
    public var publicBaseUrl: String
    public var libraryEnabled: Bool
    public var transferMode: String
    public var aiyingEnabled: Bool
    public var aiyingTgId: String
    public var aiyingChillToken: String

    public init(enabled: Bool = true, publicBaseUrl: String = "", libraryEnabled: Bool = true, transferMode: String = "series", aiyingEnabled: Bool = false, aiyingTgId: String = "", aiyingChillToken: String = "") {
        self.enabled = enabled
        self.publicBaseUrl = publicBaseUrl
        self.libraryEnabled = libraryEnabled
        self.transferMode = transferMode
        self.aiyingEnabled = aiyingEnabled
        self.aiyingTgId = aiyingTgId
        self.aiyingChillToken = aiyingChillToken
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case publicBaseUrl = "public_base_url"
        case libraryEnabled = "library_enabled"
        case transferMode = "transfer_mode"
        case aiyingEnabled = "aiying_enabled"
        case aiyingTgId = "aiying_tg_id"
        case aiyingChillToken = "aiying_chill_token"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        self.publicBaseUrl = try c.decodeIfPresent(String.self, forKey: .publicBaseUrl) ?? ""
        self.libraryEnabled = try c.decodeIfPresent(Bool.self, forKey: .libraryEnabled) ?? true
        self.transferMode = try c.decodeIfPresent(String.self, forKey: .transferMode) ?? "series"
        self.aiyingEnabled = try c.decodeIfPresent(Bool.self, forKey: .aiyingEnabled) ?? false
        self.aiyingTgId = try c.decodeIfPresent(String.self, forKey: .aiyingTgId) ?? ""
        self.aiyingChillToken = try c.decodeIfPresent(String.self, forKey: .aiyingChillToken) ?? ""
    }
}

/// HTTPValidationError
public struct HTTPValidationError: Codable, Hashable, Sendable {
    public var detail: [ValidationError]?

    public init(detail: [ValidationError]? = nil) {
        self.detail = detail
    }

    enum CodingKeys: String, CodingKey {
        case detail
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.detail = try c.decodeIfPresent([ValidationError].self, forKey: .detail)
    }
}

/// HistoryRecordPayload
public struct HistoryRecordPayload: Codable, Hashable, Sendable {
    public var status: String
    public var taskId: String
    public var jobId: String
    public var key: String
    public var path: String
    public var relativePath: String
    public var filename: String
    public var queuedAt: Int
    public var finishedAt: Int
    public var failedAt: Int

    public init(status: String, taskId: String = "", jobId: String = "", key: String = "", path: String = "", relativePath: String = "", filename: String = "", queuedAt: Int = 0, finishedAt: Int = 0, failedAt: Int = 0) {
        self.status = status
        self.taskId = taskId
        self.jobId = jobId
        self.key = key
        self.path = path
        self.relativePath = relativePath
        self.filename = filename
        self.queuedAt = queuedAt
        self.finishedAt = finishedAt
        self.failedAt = failedAt
    }

    enum CodingKeys: String, CodingKey {
        case status
        case taskId = "task_id"
        case jobId = "job_id"
        case key
        case path
        case relativePath = "relative_path"
        case filename
        case queuedAt = "queued_at"
        case finishedAt = "finished_at"
        case failedAt = "failed_at"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try c.decode(String.self, forKey: .status)
        self.taskId = try c.decodeIfPresent(String.self, forKey: .taskId) ?? ""
        self.jobId = try c.decodeIfPresent(String.self, forKey: .jobId) ?? ""
        self.key = try c.decodeIfPresent(String.self, forKey: .key) ?? ""
        self.path = try c.decodeIfPresent(String.self, forKey: .path) ?? ""
        self.relativePath = try c.decodeIfPresent(String.self, forKey: .relativePath) ?? ""
        self.filename = try c.decodeIfPresent(String.self, forKey: .filename) ?? ""
        self.queuedAt = try c.decodeIfPresent(Int.self, forKey: .queuedAt) ?? 0
        self.finishedAt = try c.decodeIfPresent(Int.self, forKey: .finishedAt) ?? 0
        self.failedAt = try c.decodeIfPresent(Int.self, forKey: .failedAt) ?? 0
    }
}

/// IdentifyTestPayload
public struct IdentifyTestPayload: Codable, Hashable, Sendable {
    public var input: String
    public var folderName: String
    public var fileName: String
    public var mediaType: String

    public init(input: String = "", folderName: String = "", fileName: String = "", mediaType: String = "auto") {
        self.input = input
        self.folderName = folderName
        self.fileName = fileName
        self.mediaType = mediaType
    }

    enum CodingKeys: String, CodingKey {
        case input
        case folderName = "folder_name"
        case fileName = "file_name"
        case mediaType = "media_type"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.input = try c.decodeIfPresent(String.self, forKey: .input) ?? ""
        self.folderName = try c.decodeIfPresent(String.self, forKey: .folderName) ?? ""
        self.fileName = try c.decodeIfPresent(String.self, forKey: .fileName) ?? ""
        self.mediaType = try c.decodeIfPresent(String.self, forKey: .mediaType) ?? "auto"
    }
}

/// IgnoreUpdatePayload
public struct IgnoreUpdatePayload: Codable, Hashable, Sendable {
    public var ignored: Bool

    public init(ignored: Bool = false) {
        self.ignored = ignored
    }

    enum CodingKeys: String, CodingKey {
        case ignored
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.ignored = try c.decodeIfPresent(Bool.self, forKey: .ignored) ?? false
    }
}

/// LocalBrowsePayload
public struct LocalBrowsePayload: Codable, Hashable, Sendable {
    public var path: String

    public init(path: String = "/") {
        self.path = path
    }

    enum CodingKeys: String, CodingKey {
        case path
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.path = try c.decodeIfPresent(String.self, forKey: .path) ?? "/"
    }
}

/// LoginRequest
public struct LoginRequest: Codable, Hashable, Sendable {
    public var username: String
    public var password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    enum CodingKeys: String, CodingKey {
        case username
        case password
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.username = try c.decode(String.self, forKey: .username)
        self.password = try c.decode(String.self, forKey: .password)
    }
}

/// ManualCleanupPayload
public struct ManualCleanupPayload: Codable, Hashable, Sendable {

    public init() {}
}

/// ManualTransferRequest
public struct ManualTransferRequest: Codable, Hashable, Sendable {
    public var link: String

    public init(link: String = "") {
        self.link = link
    }

    enum CodingKeys: String, CodingKey {
        case link
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.link = try c.decodeIfPresent(String.self, forKey: .link) ?? ""
    }
}

/// MediaOrganizeConfig
public struct MediaOrganizeConfig: Codable, Hashable, Sendable {
    public var driveIndex: Int
    public var sourceCid: String
    public var sourceName: String
    public var targetCid: String
    public var targetName: String
    public var failedCid: String
    public var failedName: String
    public var dedupCid: String
    public var dedupName: String
    public var washCid: String
    public var washName: String
    public var scrapeEnabled: Bool
    public var embyLocalScrape: Bool
    public var scrapeNfo: Bool
    public var scrapePoster: Bool
    public var scrapeFanart: Bool
    public var scrapeLogo: Bool
    public var scrapeBanner: Bool
    public var scrapeThumb: Bool
    public var scrapeSeasonPoster: Bool
    public var scrapeEpisodeThumb: Bool
    public var policyNfo: String
    public var policyPoster: String
    public var policyFanart: String
    public var policyLogo: String
    public var policyBanner: String
    public var policyThumb: String
    public var policySeasonPoster: String
    public var policyEpisodeThumb: String
    public var metadataRepairEpisodeConditions: [String]?
    public var metadataRepairImageConditions: [String]?
    public var metadataRepairLookbackDays: Int
    public var metadataRepairWorkers: Int
    public var metadataRepairTvLibraries: [String]?
    public var lifeMonitorEnabled: Bool
    public var lifeMonitorStartMode: String
    public var autoSyncStrm: Bool
    public var embyScrapersEnabled: Bool
    public var washEnabled: Bool
    public var washByEquivalentSize: Bool
    public var washToleranceRatio: Double
    public var washReserved1: Bool
    public var washReserved2: Bool
    public var organizeParseMode: String
    public var movieFolderFormat: String
    public var movieRenameFormat: String
    public var tvFolderFormat: String
    public var tvSeasonFolderFormat: String
    public var tvEpisodeFormat: String

    public init(driveIndex: Int = 0, sourceCid: String = "0", sourceName: String = "根目录", targetCid: String = "0", targetName: String = "根目录", failedCid: String = "0", failedName: String = "根目录", dedupCid: String = "0", dedupName: String = "根目录", washCid: String = "0", washName: String = "根目录", scrapeEnabled: Bool = true, embyLocalScrape: Bool = true, scrapeNfo: Bool = true, scrapePoster: Bool = true, scrapeFanart: Bool = true, scrapeLogo: Bool = true, scrapeBanner: Bool = true, scrapeThumb: Bool = true, scrapeSeasonPoster: Bool = true, scrapeEpisodeThumb: Bool = true, policyNfo: String = "missing_only", policyPoster: String = "missing_only", policyFanart: String = "missing_only", policyLogo: String = "missing_only", policyBanner: String = "missing_only", policyThumb: String = "missing_only", policySeasonPoster: String = "missing_only", policyEpisodeThumb: String = "missing_only", metadataRepairEpisodeConditions: [String]? = nil, metadataRepairImageConditions: [String]? = nil, metadataRepairLookbackDays: Int = 60, metadataRepairWorkers: Int = 8, metadataRepairTvLibraries: [String]? = nil, lifeMonitorEnabled: Bool = true, lifeMonitorStartMode: String = "last", autoSyncStrm: Bool = true, embyScrapersEnabled: Bool = false, washEnabled: Bool = true, washByEquivalentSize: Bool = true, washToleranceRatio: Double = 0.0, washReserved1: Bool = false, washReserved2: Bool = false, organizeParseMode: String = "ffprobe", movieFolderFormat: String = "{title} ({year}) {tmdb-{tmdb_id}}", movieRenameFormat: String = "{en_title}.{year}.{resource_pix}.{web_source}.{resource_type}.{resource_effect}.{video_encode}.{color_depth}.{video_effect}.{fps}.{audio_encode}-{resource_team}", tvFolderFormat: String = "{title} ({year}) {tmdb-{tmdb_id}}", tvSeasonFolderFormat: String = "Season {season_num}", tvEpisodeFormat: String = "{en_title}.{season_episode}.{year}.{resource_pix}.{web_source}.{resource_type}.{video_encode}.{color_depth}.{video_effect}.{fps}.{audio_encode}-{resource_team}") {
        self.driveIndex = driveIndex
        self.sourceCid = sourceCid
        self.sourceName = sourceName
        self.targetCid = targetCid
        self.targetName = targetName
        self.failedCid = failedCid
        self.failedName = failedName
        self.dedupCid = dedupCid
        self.dedupName = dedupName
        self.washCid = washCid
        self.washName = washName
        self.scrapeEnabled = scrapeEnabled
        self.embyLocalScrape = embyLocalScrape
        self.scrapeNfo = scrapeNfo
        self.scrapePoster = scrapePoster
        self.scrapeFanart = scrapeFanart
        self.scrapeLogo = scrapeLogo
        self.scrapeBanner = scrapeBanner
        self.scrapeThumb = scrapeThumb
        self.scrapeSeasonPoster = scrapeSeasonPoster
        self.scrapeEpisodeThumb = scrapeEpisodeThumb
        self.policyNfo = policyNfo
        self.policyPoster = policyPoster
        self.policyFanart = policyFanart
        self.policyLogo = policyLogo
        self.policyBanner = policyBanner
        self.policyThumb = policyThumb
        self.policySeasonPoster = policySeasonPoster
        self.policyEpisodeThumb = policyEpisodeThumb
        self.metadataRepairEpisodeConditions = metadataRepairEpisodeConditions
        self.metadataRepairImageConditions = metadataRepairImageConditions
        self.metadataRepairLookbackDays = metadataRepairLookbackDays
        self.metadataRepairWorkers = metadataRepairWorkers
        self.metadataRepairTvLibraries = metadataRepairTvLibraries
        self.lifeMonitorEnabled = lifeMonitorEnabled
        self.lifeMonitorStartMode = lifeMonitorStartMode
        self.autoSyncStrm = autoSyncStrm
        self.embyScrapersEnabled = embyScrapersEnabled
        self.washEnabled = washEnabled
        self.washByEquivalentSize = washByEquivalentSize
        self.washToleranceRatio = washToleranceRatio
        self.washReserved1 = washReserved1
        self.washReserved2 = washReserved2
        self.organizeParseMode = organizeParseMode
        self.movieFolderFormat = movieFolderFormat
        self.movieRenameFormat = movieRenameFormat
        self.tvFolderFormat = tvFolderFormat
        self.tvSeasonFolderFormat = tvSeasonFolderFormat
        self.tvEpisodeFormat = tvEpisodeFormat
    }

    enum CodingKeys: String, CodingKey {
        case driveIndex = "drive_index"
        case sourceCid = "source_cid"
        case sourceName = "source_name"
        case targetCid = "target_cid"
        case targetName = "target_name"
        case failedCid = "failed_cid"
        case failedName = "failed_name"
        case dedupCid = "dedup_cid"
        case dedupName = "dedup_name"
        case washCid = "wash_cid"
        case washName = "wash_name"
        case scrapeEnabled = "scrape_enabled"
        case embyLocalScrape = "emby_local_scrape"
        case scrapeNfo = "scrape_nfo"
        case scrapePoster = "scrape_poster"
        case scrapeFanart = "scrape_fanart"
        case scrapeLogo = "scrape_logo"
        case scrapeBanner = "scrape_banner"
        case scrapeThumb = "scrape_thumb"
        case scrapeSeasonPoster = "scrape_season_poster"
        case scrapeEpisodeThumb = "scrape_episode_thumb"
        case policyNfo = "policy_nfo"
        case policyPoster = "policy_poster"
        case policyFanart = "policy_fanart"
        case policyLogo = "policy_logo"
        case policyBanner = "policy_banner"
        case policyThumb = "policy_thumb"
        case policySeasonPoster = "policy_season_poster"
        case policyEpisodeThumb = "policy_episode_thumb"
        case metadataRepairEpisodeConditions = "metadata_repair_episode_conditions"
        case metadataRepairImageConditions = "metadata_repair_image_conditions"
        case metadataRepairLookbackDays = "metadata_repair_lookback_days"
        case metadataRepairWorkers = "metadata_repair_workers"
        case metadataRepairTvLibraries = "metadata_repair_tv_libraries"
        case lifeMonitorEnabled = "life_monitor_enabled"
        case lifeMonitorStartMode = "life_monitor_start_mode"
        case autoSyncStrm = "auto_sync_strm"
        case embyScrapersEnabled = "emby_scrapers_enabled"
        case washEnabled = "wash_enabled"
        case washByEquivalentSize = "wash_by_equivalent_size"
        case washToleranceRatio = "wash_tolerance_ratio"
        case washReserved1 = "wash_reserved_1"
        case washReserved2 = "wash_reserved_2"
        case organizeParseMode = "organize_parse_mode"
        case movieFolderFormat = "movie_folder_format"
        case movieRenameFormat = "movie_rename_format"
        case tvFolderFormat = "tv_folder_format"
        case tvSeasonFolderFormat = "tv_season_folder_format"
        case tvEpisodeFormat = "tv_episode_format"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.driveIndex = try c.decodeIfPresent(Int.self, forKey: .driveIndex) ?? 0
        self.sourceCid = try c.decodeIfPresent(String.self, forKey: .sourceCid) ?? "0"
        self.sourceName = try c.decodeIfPresent(String.self, forKey: .sourceName) ?? "根目录"
        self.targetCid = try c.decodeIfPresent(String.self, forKey: .targetCid) ?? "0"
        self.targetName = try c.decodeIfPresent(String.self, forKey: .targetName) ?? "根目录"
        self.failedCid = try c.decodeIfPresent(String.self, forKey: .failedCid) ?? "0"
        self.failedName = try c.decodeIfPresent(String.self, forKey: .failedName) ?? "根目录"
        self.dedupCid = try c.decodeIfPresent(String.self, forKey: .dedupCid) ?? "0"
        self.dedupName = try c.decodeIfPresent(String.self, forKey: .dedupName) ?? "根目录"
        self.washCid = try c.decodeIfPresent(String.self, forKey: .washCid) ?? "0"
        self.washName = try c.decodeIfPresent(String.self, forKey: .washName) ?? "根目录"
        self.scrapeEnabled = try c.decodeIfPresent(Bool.self, forKey: .scrapeEnabled) ?? true
        self.embyLocalScrape = try c.decodeIfPresent(Bool.self, forKey: .embyLocalScrape) ?? true
        self.scrapeNfo = try c.decodeIfPresent(Bool.self, forKey: .scrapeNfo) ?? true
        self.scrapePoster = try c.decodeIfPresent(Bool.self, forKey: .scrapePoster) ?? true
        self.scrapeFanart = try c.decodeIfPresent(Bool.self, forKey: .scrapeFanart) ?? true
        self.scrapeLogo = try c.decodeIfPresent(Bool.self, forKey: .scrapeLogo) ?? true
        self.scrapeBanner = try c.decodeIfPresent(Bool.self, forKey: .scrapeBanner) ?? true
        self.scrapeThumb = try c.decodeIfPresent(Bool.self, forKey: .scrapeThumb) ?? true
        self.scrapeSeasonPoster = try c.decodeIfPresent(Bool.self, forKey: .scrapeSeasonPoster) ?? true
        self.scrapeEpisodeThumb = try c.decodeIfPresent(Bool.self, forKey: .scrapeEpisodeThumb) ?? true
        self.policyNfo = try c.decodeIfPresent(String.self, forKey: .policyNfo) ?? "missing_only"
        self.policyPoster = try c.decodeIfPresent(String.self, forKey: .policyPoster) ?? "missing_only"
        self.policyFanart = try c.decodeIfPresent(String.self, forKey: .policyFanart) ?? "missing_only"
        self.policyLogo = try c.decodeIfPresent(String.self, forKey: .policyLogo) ?? "missing_only"
        self.policyBanner = try c.decodeIfPresent(String.self, forKey: .policyBanner) ?? "missing_only"
        self.policyThumb = try c.decodeIfPresent(String.self, forKey: .policyThumb) ?? "missing_only"
        self.policySeasonPoster = try c.decodeIfPresent(String.self, forKey: .policySeasonPoster) ?? "missing_only"
        self.policyEpisodeThumb = try c.decodeIfPresent(String.self, forKey: .policyEpisodeThumb) ?? "missing_only"
        self.metadataRepairEpisodeConditions = try c.decodeIfPresent([String].self, forKey: .metadataRepairEpisodeConditions)
        self.metadataRepairImageConditions = try c.decodeIfPresent([String].self, forKey: .metadataRepairImageConditions)
        self.metadataRepairLookbackDays = try c.decodeIfPresent(Int.self, forKey: .metadataRepairLookbackDays) ?? 60
        self.metadataRepairWorkers = try c.decodeIfPresent(Int.self, forKey: .metadataRepairWorkers) ?? 8
        self.metadataRepairTvLibraries = try c.decodeIfPresent([String].self, forKey: .metadataRepairTvLibraries)
        self.lifeMonitorEnabled = try c.decodeIfPresent(Bool.self, forKey: .lifeMonitorEnabled) ?? true
        self.lifeMonitorStartMode = try c.decodeIfPresent(String.self, forKey: .lifeMonitorStartMode) ?? "last"
        self.autoSyncStrm = try c.decodeIfPresent(Bool.self, forKey: .autoSyncStrm) ?? true
        self.embyScrapersEnabled = try c.decodeIfPresent(Bool.self, forKey: .embyScrapersEnabled) ?? false
        self.washEnabled = try c.decodeIfPresent(Bool.self, forKey: .washEnabled) ?? true
        self.washByEquivalentSize = try c.decodeIfPresent(Bool.self, forKey: .washByEquivalentSize) ?? true
        self.washToleranceRatio = try c.decodeIfPresent(Double.self, forKey: .washToleranceRatio) ?? 0.0
        self.washReserved1 = try c.decodeIfPresent(Bool.self, forKey: .washReserved1) ?? false
        self.washReserved2 = try c.decodeIfPresent(Bool.self, forKey: .washReserved2) ?? false
        self.organizeParseMode = try c.decodeIfPresent(String.self, forKey: .organizeParseMode) ?? "ffprobe"
        self.movieFolderFormat = try c.decodeIfPresent(String.self, forKey: .movieFolderFormat) ?? "{title} ({year}) {tmdb-{tmdb_id}}"
        self.movieRenameFormat = try c.decodeIfPresent(String.self, forKey: .movieRenameFormat) ?? "{en_title}.{year}.{resource_pix}.{web_source}.{resource_type}.{resource_effect}.{video_encode}.{color_depth}.{video_effect}.{fps}.{audio_encode}-{resource_team}"
        self.tvFolderFormat = try c.decodeIfPresent(String.self, forKey: .tvFolderFormat) ?? "{title} ({year}) {tmdb-{tmdb_id}}"
        self.tvSeasonFolderFormat = try c.decodeIfPresent(String.self, forKey: .tvSeasonFolderFormat) ?? "Season {season_num}"
        self.tvEpisodeFormat = try c.decodeIfPresent(String.self, forKey: .tvEpisodeFormat) ?? "{en_title}.{season_episode}.{year}.{resource_pix}.{web_source}.{resource_type}.{video_encode}.{color_depth}.{video_effect}.{fps}.{audio_encode}-{resource_team}"
    }
}

/// MoviePilotConfigModel
public struct MoviePilotConfigModel: Codable, Hashable, Sendable {
    public var mpUrl: String
    public var mpUsername: String
    public var mpPassword: String

    public init(mpUrl: String = "", mpUsername: String = "", mpPassword: String = "") {
        self.mpUrl = mpUrl
        self.mpUsername = mpUsername
        self.mpPassword = mpPassword
    }

    enum CodingKeys: String, CodingKey {
        case mpUrl = "mp_url"
        case mpUsername = "mp_username"
        case mpPassword = "mp_password"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.mpUrl = try c.decodeIfPresent(String.self, forKey: .mpUrl) ?? ""
        self.mpUsername = try c.decodeIfPresent(String.self, forKey: .mpUsername) ?? ""
        self.mpPassword = try c.decodeIfPresent(String.self, forKey: .mpPassword) ?? ""
    }
}

/// OrganizeRequest
public struct OrganizeRequest: Codable, Hashable, Sendable {
    public var mediaType: String
    public var isBluray: Bool
    public var overwrite: Bool

    public init(mediaType: String = "", isBluray: Bool = false, overwrite: Bool = false) {
        self.mediaType = mediaType
        self.isBluray = isBluray
        self.overwrite = overwrite
    }

    enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
        case isBluray = "is_bluray"
        case overwrite
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.mediaType = try c.decodeIfPresent(String.self, forKey: .mediaType) ?? ""
        self.isBluray = try c.decodeIfPresent(Bool.self, forKey: .isBluray) ?? false
        self.overwrite = try c.decodeIfPresent(Bool.self, forKey: .overwrite) ?? false
    }
}

/// PreviewRequest
public struct PreviewRequest: Codable, Hashable, Sendable {
    public var url: String
    public var key: String
    public var publicHost: String?
    public var libraryId: String
    public var config: JSONValue
    public var imageData: String?
    public var customAssets: JSONValue?
    public var mode: String

    public init(url: String, key: String, publicHost: String? = nil, libraryId: String, config: JSONValue, imageData: String? = nil, customAssets: JSONValue? = nil, mode: String = "random") {
        self.url = url
        self.key = key
        self.publicHost = publicHost
        self.libraryId = libraryId
        self.config = config
        self.imageData = imageData
        self.customAssets = customAssets
        self.mode = mode
    }

    enum CodingKeys: String, CodingKey {
        case url
        case key
        case publicHost = "public_host"
        case libraryId = "library_id"
        case config
        case imageData = "image_data"
        case customAssets = "custom_assets"
        case mode
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try c.decode(String.self, forKey: .url)
        self.key = try c.decode(String.self, forKey: .key)
        self.publicHost = try c.decodeIfPresent(String.self, forKey: .publicHost)
        self.libraryId = try c.decode(String.self, forKey: .libraryId)
        self.config = try c.decode(JSONValue.self, forKey: .config)
        self.imageData = try c.decodeIfPresent(String.self, forKey: .imageData)
        self.customAssets = try c.decodeIfPresent(JSONValue.self, forKey: .customAssets)
        self.mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "random"
    }
}

/// PullImagePayload
public struct PullImagePayload: Codable, Hashable, Sendable {
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

/// RedoOrganizeHistoryPayload
public struct RedoOrganizeHistoryPayload: Codable, Hashable, Sendable {
    public var historyIds: [String]?
    public var reason: String
    public var recognitionIdentity: JSONValue?
    public var recognitionIdentities: JSONValue?

    public init(historyIds: [String]? = nil, reason: String = "", recognitionIdentity: JSONValue? = nil, recognitionIdentities: JSONValue? = nil) {
        self.historyIds = historyIds
        self.reason = reason
        self.recognitionIdentity = recognitionIdentity
        self.recognitionIdentities = recognitionIdentities
    }

    enum CodingKeys: String, CodingKey {
        case historyIds = "history_ids"
        case reason
        case recognitionIdentity = "recognition_identity"
        case recognitionIdentities = "recognition_identities"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.historyIds = try c.decodeIfPresent([String].self, forKey: .historyIds)
        self.reason = try c.decodeIfPresent(String.self, forKey: .reason) ?? ""
        self.recognitionIdentity = try c.decodeIfPresent(JSONValue.self, forKey: .recognitionIdentity)
        self.recognitionIdentities = try c.decodeIfPresent(JSONValue.self, forKey: .recognitionIdentities)
    }
}

/// RegistryAuthPayload
public struct RegistryAuthPayload: Codable, Hashable, Sendable {
    public var username: String
    public var token: String

    public init(username: String = "", token: String = "") {
        self.username = username
        self.token = token
    }

    enum CodingKeys: String, CodingKey {
        case username
        case token
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.username = try c.decodeIfPresent(String.self, forKey: .username) ?? ""
        self.token = try c.decodeIfPresent(String.self, forKey: .token) ?? ""
    }
}

/// ResolveIconPayload
public struct ResolveIconPayload: Codable, Hashable, Sendable {
    public var url: String

    public init(url: String = "") {
        self.url = url
    }

    enum CodingKeys: String, CodingKey {
        case url
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try c.decodeIfPresent(String.self, forKey: .url) ?? ""
    }
}

/// ResourceDownloadRequest
public struct ResourceDownloadRequest: Codable, Hashable, Sendable {
    public var source: String
    public var resourceId: String
    public var typeValue: String
    public var tmdbId: String
    public var title: String
    public var year: String
    public var season: Int?
    public var episode: Int?
    public var fillMode: String
    public var existingEpisodesBySeason: JSONValue?

    public init(source: String = "aiying", resourceId: String = "", typeValue: String = "movie", tmdbId: String = "", title: String = "", year: String = "", season: Int? = nil, episode: Int? = nil, fillMode: String = "full", existingEpisodesBySeason: JSONValue? = nil) {
        self.source = source
        self.resourceId = resourceId
        self.typeValue = typeValue
        self.tmdbId = tmdbId
        self.title = title
        self.year = year
        self.season = season
        self.episode = episode
        self.fillMode = fillMode
        self.existingEpisodesBySeason = existingEpisodesBySeason
    }

    enum CodingKeys: String, CodingKey {
        case source
        case resourceId = "resource_id"
        case typeValue = "type"
        case tmdbId = "tmdb_id"
        case title
        case year
        case season
        case episode
        case fillMode = "fill_mode"
        case existingEpisodesBySeason = "existing_episodes_by_season"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.source = try c.decodeIfPresent(String.self, forKey: .source) ?? "aiying"
        self.resourceId = try c.decodeIfPresent(String.self, forKey: .resourceId) ?? ""
        self.typeValue = try c.decodeIfPresent(String.self, forKey: .typeValue) ?? "movie"
        self.tmdbId = try c.decodeIfPresent(String.self, forKey: .tmdbId) ?? ""
        self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.year = try c.decodeIfPresent(String.self, forKey: .year) ?? ""
        self.season = try c.decodeIfPresent(Int.self, forKey: .season)
        self.episode = try c.decodeIfPresent(Int.self, forKey: .episode)
        self.fillMode = try c.decodeIfPresent(String.self, forKey: .fillMode) ?? "full"
        self.existingEpisodesBySeason = try c.decodeIfPresent(JSONValue.self, forKey: .existingEpisodesBySeason)
    }
}

/// ResourcePreviewRequest
public struct ResourcePreviewRequest: Codable, Hashable, Sendable {
    public var source: String
    public var resourceId: String
    public var typeValue: String
    public var tmdbId: String
    public var title: String
    public var year: String
    public var season: Int?
    public var episode: Int?

    public init(source: String = "aiying", resourceId: String = "", typeValue: String = "movie", tmdbId: String = "", title: String = "", year: String = "", season: Int? = nil, episode: Int? = nil) {
        self.source = source
        self.resourceId = resourceId
        self.typeValue = typeValue
        self.tmdbId = tmdbId
        self.title = title
        self.year = year
        self.season = season
        self.episode = episode
    }

    enum CodingKeys: String, CodingKey {
        case source
        case resourceId = "resource_id"
        case typeValue = "type"
        case tmdbId = "tmdb_id"
        case title
        case year
        case season
        case episode
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.source = try c.decodeIfPresent(String.self, forKey: .source) ?? "aiying"
        self.resourceId = try c.decodeIfPresent(String.self, forKey: .resourceId) ?? ""
        self.typeValue = try c.decodeIfPresent(String.self, forKey: .typeValue) ?? "movie"
        self.tmdbId = try c.decodeIfPresent(String.self, forKey: .tmdbId) ?? ""
        self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.year = try c.decodeIfPresent(String.self, forKey: .year) ?? ""
        self.season = try c.decodeIfPresent(Int.self, forKey: .season)
        self.episode = try c.decodeIfPresent(Int.self, forKey: .episode)
    }
}

/// ResourceSearchRequest
public struct ResourceSearchRequest: Codable, Hashable, Sendable {
    public var typeValue: String
    public var tmdbId: String
    public var title: String
    public var year: String
    public var season: Int?
    public var episode: Int?
    public var sources: [String]?

    public init(typeValue: String = "movie", tmdbId: String = "", title: String = "", year: String = "", season: Int? = nil, episode: Int? = nil, sources: [String]? = nil) {
        self.typeValue = typeValue
        self.tmdbId = tmdbId
        self.title = title
        self.year = year
        self.season = season
        self.episode = episode
        self.sources = sources
    }

    enum CodingKeys: String, CodingKey {
        case typeValue = "type"
        case tmdbId = "tmdb_id"
        case title
        case year
        case season
        case episode
        case sources
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.typeValue = try c.decodeIfPresent(String.self, forKey: .typeValue) ?? "movie"
        self.tmdbId = try c.decodeIfPresent(String.self, forKey: .tmdbId) ?? ""
        self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.year = try c.decodeIfPresent(String.self, forKey: .year) ?? ""
        self.season = try c.decodeIfPresent(Int.self, forKey: .season)
        self.episode = try c.decodeIfPresent(Int.self, forKey: .episode)
        self.sources = try c.decodeIfPresent([String].self, forKey: .sources)
    }
}

/// ResourceTestRequest
public struct ResourceTestRequest: Codable, Hashable, Sendable {
    public var typeValue: String
    public var tmdbId: String

    public init(typeValue: String = "movie", tmdbId: String = "") {
        self.typeValue = typeValue
        self.tmdbId = tmdbId
    }

    enum CodingKeys: String, CodingKey {
        case typeValue = "type"
        case tmdbId = "tmdb_id"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.typeValue = try c.decodeIfPresent(String.self, forKey: .typeValue) ?? "movie"
        self.tmdbId = try c.decodeIfPresent(String.self, forKey: .tmdbId) ?? ""
    }
}

/// ResourceTransferRequest
public struct ResourceTransferRequest: Codable, Hashable, Sendable {
    public var source: String
    public var resourceId: String
    public var typeValue: String
    public var tmdbId: String
    public var title: String
    public var year: String
    public var season: Int?
    public var episode: Int?

    public init(source: String = "aiying", resourceId: String = "", typeValue: String = "movie", tmdbId: String = "", title: String = "", year: String = "", season: Int? = nil, episode: Int? = nil) {
        self.source = source
        self.resourceId = resourceId
        self.typeValue = typeValue
        self.tmdbId = tmdbId
        self.title = title
        self.year = year
        self.season = season
        self.episode = episode
    }

    enum CodingKeys: String, CodingKey {
        case source
        case resourceId = "resource_id"
        case typeValue = "type"
        case tmdbId = "tmdb_id"
        case title
        case year
        case season
        case episode
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.source = try c.decodeIfPresent(String.self, forKey: .source) ?? "aiying"
        self.resourceId = try c.decodeIfPresent(String.self, forKey: .resourceId) ?? ""
        self.typeValue = try c.decodeIfPresent(String.self, forKey: .typeValue) ?? "movie"
        self.tmdbId = try c.decodeIfPresent(String.self, forKey: .tmdbId) ?? ""
        self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.year = try c.decodeIfPresent(String.self, forKey: .year) ?? ""
        self.season = try c.decodeIfPresent(Int.self, forKey: .season)
        self.episode = try c.decodeIfPresent(Int.self, forKey: .episode)
    }
}

/// Result115QrPayload
public struct Result115QrPayload: Codable, Hashable, Sendable {
    public var uid: String
    public var app: String

    public init(uid: String, app: String = "115android") {
        self.uid = uid
        self.app = app
    }

    enum CodingKeys: String, CodingKey {
        case uid
        case app
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try c.decode(String.self, forKey: .uid)
        self.app = try c.decodeIfPresent(String.self, forKey: .app) ?? "115android"
    }
}

/// RetryPayload
public struct RetryPayload: Codable, Hashable, Sendable {
    public var jobId: String

    public init(jobId: String) {
        self.jobId = jobId
    }

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.jobId = try c.decode(String.self, forKey: .jobId)
    }
}

/// RssBuildUrlRequest
public struct RssBuildUrlRequest: Codable, Hashable, Sendable {
    public var presetId: String
    public var params: JSONValue?
    public var proxy: Bool

    public init(presetId: String, params: JSONValue? = nil, proxy: Bool = true) {
        self.presetId = presetId
        self.params = params
        self.proxy = proxy
    }

    enum CodingKeys: String, CodingKey {
        case presetId = "preset_id"
        case params
        case proxy
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.presetId = try c.decode(String.self, forKey: .presetId)
        self.params = try c.decodeIfPresent(JSONValue.self, forKey: .params)
        self.proxy = try c.decodeIfPresent(Bool.self, forKey: .proxy) ?? true
    }
}

/// RssGlobalConfig
public struct RssGlobalConfig: Codable, Hashable, Sendable {
    public var sourceRoot: String
    public var linkRoot: String

    public init(sourceRoot: String, linkRoot: String) {
        self.sourceRoot = sourceRoot
        self.linkRoot = linkRoot
    }

    enum CodingKeys: String, CodingKey {
        case sourceRoot = "source_root"
        case linkRoot = "link_root"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.sourceRoot = try c.decode(String.self, forKey: .sourceRoot)
        self.linkRoot = try c.decode(String.self, forKey: .linkRoot)
    }
}

/// RssPreviewRequest
public struct RssPreviewRequest: Codable, Hashable, Sendable {
    public var rssUrl: String
    public var contentType: String
    public var limit: Int

    public init(rssUrl: String, contentType: String = "movies", limit: Int = 10) {
        self.rssUrl = rssUrl
        self.contentType = contentType
        self.limit = limit
    }

    enum CodingKeys: String, CodingKey {
        case rssUrl = "rss_url"
        case contentType = "content_type"
        case limit
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.rssUrl = try c.decode(String.self, forKey: .rssUrl)
        self.contentType = try c.decodeIfPresent(String.self, forKey: .contentType) ?? "movies"
        self.limit = try c.decodeIfPresent(Int.self, forKey: .limit) ?? 10
    }
}

/// RssSourcePatchPayload
public struct RssSourcePatchPayload: Codable, Hashable, Sendable {
    public var name: String?
    public var rssUrl: String?
    public var mediaType: String?
    public var subscriptionTarget: String?
    public var cron: String?
    public var enabled: Bool?

    public init(name: String? = nil, rssUrl: String? = nil, mediaType: String? = nil, subscriptionTarget: String? = nil, cron: String? = nil, enabled: Bool? = nil) {
        self.name = name
        self.rssUrl = rssUrl
        self.mediaType = mediaType
        self.subscriptionTarget = subscriptionTarget
        self.cron = cron
        self.enabled = enabled
    }

    enum CodingKeys: String, CodingKey {
        case name
        case rssUrl = "rss_url"
        case mediaType = "media_type"
        case subscriptionTarget = "subscription_target"
        case cron
        case enabled
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try c.decodeIfPresent(String.self, forKey: .name)
        self.rssUrl = try c.decodeIfPresent(String.self, forKey: .rssUrl)
        self.mediaType = try c.decodeIfPresent(String.self, forKey: .mediaType)
        self.subscriptionTarget = try c.decodeIfPresent(String.self, forKey: .subscriptionTarget)
        self.cron = try c.decodeIfPresent(String.self, forKey: .cron)
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled)
    }
}

/// RssSourcePayload
public struct RssSourcePayload: Codable, Hashable, Sendable {
    public var name: String
    public var rssUrl: String
    public var mediaType: String
    public var subscriptionTarget: String
    public var cron: String
    public var enabled: Bool

    public init(name: String = "", rssUrl: String = "", mediaType: String = "tv", subscriptionTarget: String = "moviepilot", cron: String = "0 */12 * * *", enabled: Bool = true) {
        self.name = name
        self.rssUrl = rssUrl
        self.mediaType = mediaType
        self.subscriptionTarget = subscriptionTarget
        self.cron = cron
        self.enabled = enabled
    }

    enum CodingKeys: String, CodingKey {
        case name
        case rssUrl = "rss_url"
        case mediaType = "media_type"
        case subscriptionTarget = "subscription_target"
        case cron
        case enabled
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.rssUrl = try c.decodeIfPresent(String.self, forKey: .rssUrl) ?? ""
        self.mediaType = try c.decodeIfPresent(String.self, forKey: .mediaType) ?? "tv"
        self.subscriptionTarget = try c.decodeIfPresent(String.self, forKey: .subscriptionTarget) ?? "moviepilot"
        self.cron = try c.decodeIfPresent(String.self, forKey: .cron) ?? "0 */12 * * *"
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
    }
}

/// RssTaskModel
public struct RssTaskModel: Codable, Hashable, Sendable {
    public var idValue: String?
    public var name: String
    public var rssUrl: String
    public var cron: String
    public var targetServerIdx: Int
    public var contentType: String
    public var syncLibraryMissingToMp: Bool
    public var enabled: Bool
    public var lastEntries: [String]?
    public var entryTmdbMap: JSONValue?
    public var lastSyncAt: Double?
    public var lastRssEntryCount: Int
    public var lastTmdbMatchedCount: Int
    public var lastHardlinkCount: Int

    public init(idValue: String? = nil, name: String, rssUrl: String, cron: String, targetServerIdx: Int = 0, contentType: String = "movies", syncLibraryMissingToMp: Bool = false, enabled: Bool = true, lastEntries: [String]? = nil, entryTmdbMap: JSONValue? = nil, lastSyncAt: Double? = nil, lastRssEntryCount: Int = 0, lastTmdbMatchedCount: Int = 0, lastHardlinkCount: Int = 0) {
        self.idValue = idValue
        self.name = name
        self.rssUrl = rssUrl
        self.cron = cron
        self.targetServerIdx = targetServerIdx
        self.contentType = contentType
        self.syncLibraryMissingToMp = syncLibraryMissingToMp
        self.enabled = enabled
        self.lastEntries = lastEntries
        self.entryTmdbMap = entryTmdbMap
        self.lastSyncAt = lastSyncAt
        self.lastRssEntryCount = lastRssEntryCount
        self.lastTmdbMatchedCount = lastTmdbMatchedCount
        self.lastHardlinkCount = lastHardlinkCount
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
        case lastEntries = "last_entries"
        case entryTmdbMap = "entry_tmdb_map"
        case lastSyncAt = "last_sync_at"
        case lastRssEntryCount = "last_rss_entry_count"
        case lastTmdbMatchedCount = "last_tmdb_matched_count"
        case lastHardlinkCount = "last_hardlink_count"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.idValue = try c.decodeIfPresent(String.self, forKey: .idValue)
        self.name = try c.decode(String.self, forKey: .name)
        self.rssUrl = try c.decode(String.self, forKey: .rssUrl)
        self.cron = try c.decode(String.self, forKey: .cron)
        self.targetServerIdx = try c.decodeIfPresent(Int.self, forKey: .targetServerIdx) ?? 0
        self.contentType = try c.decodeIfPresent(String.self, forKey: .contentType) ?? "movies"
        self.syncLibraryMissingToMp = try c.decodeIfPresent(Bool.self, forKey: .syncLibraryMissingToMp) ?? false
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        self.lastEntries = try c.decodeIfPresent([String].self, forKey: .lastEntries)
        self.entryTmdbMap = try c.decodeIfPresent(JSONValue.self, forKey: .entryTmdbMap)
        self.lastSyncAt = try c.decodeIfPresent(Double.self, forKey: .lastSyncAt)
        self.lastRssEntryCount = try c.decodeIfPresent(Int.self, forKey: .lastRssEntryCount) ?? 0
        self.lastTmdbMatchedCount = try c.decodeIfPresent(Int.self, forKey: .lastTmdbMatchedCount) ?? 0
        self.lastHardlinkCount = try c.decodeIfPresent(Int.self, forKey: .lastHardlinkCount) ?? 0
    }
}

/// RunSavedTaskRequest
public struct RunSavedTaskRequest: Codable, Hashable, Sendable {
    public var idValue: String

    public init(idValue: String) {
        self.idValue = idValue
    }

    enum CodingKeys: String, CodingKey {
        case idValue = "id"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.idValue = try c.decode(String.self, forKey: .idValue)
    }
}

/// RunTaskRequest
public struct RunTaskRequest: Codable, Hashable, Sendable {
    public var presetFilename: String
    public var targets: [TaskTarget]
    public var mode: String

    public init(presetFilename: String, targets: [TaskTarget], mode: String = "random") {
        self.presetFilename = presetFilename
        self.targets = targets
        self.mode = mode
    }

    enum CodingKeys: String, CodingKey {
        case presetFilename = "preset_filename"
        case targets
        case mode
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.presetFilename = try c.decode(String.self, forKey: .presetFilename)
        self.targets = try c.decode([TaskTarget].self, forKey: .targets)
        self.mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "random"
    }
}
