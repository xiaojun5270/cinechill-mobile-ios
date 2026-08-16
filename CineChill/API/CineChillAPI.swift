// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// CineChill 服务端接口总入口，按 OpenAPI tag 分组。
public struct CineChillAPI: Sendable {
    public let client: APIClient

    public init(client: APIClient) { self.client = client }

    /// `AIEpisodeResolver`
    public var ai: AIAssistantAPI { AIAssistantAPI(client: client) }

    /// `Auth`
    public var auth: AuthAPI { AuthAPI(client: client) }

    /// `Discover`
    public var discover: DiscoverAPI { DiscoverAPI(client: client) }

    /// `DockerManager`
    public var docker: DockerAPI { DockerAPI(client: client) }

    /// `Drive115Cleanup`
    public var cleanup115: Drive115CleanupAPI { Drive115CleanupAPI(client: client) }

    /// `Drive115Upload`
    public var upload115: Drive115UploadAPI { Drive115UploadAPI(client: client) }

    /// `EmbyTasks`
    public var embyTasks: EmbyTasksAPI { EmbyTasksAPI(client: client) }

    /// `EmbyUsers`
    public var embyUsers: EmbyUsersAPI { EmbyUsersAPI(client: client) }

    /// `FnosSign`
    public var fnosSign: FnosSignAPI { FnosSignAPI(client: client) }

    /// `ForwardAiying`
    public var forward: ForwardAPI { ForwardAPI(client: client) }

    /// `MoviePilot`
    public var moviePilot: MoviePilotAPI { MoviePilotAPI(client: client) }

    /// `Notify`
    public var notify: NotifyAPI { NotifyAPI(client: client) }

    /// `OrganizeHistory`
    public var organizeHistory: OrganizeHistoryAPI { OrganizeHistoryAPI(client: client) }

    /// `RSS`
    public var rss: RSSAPI { RSSAPI(client: client) }

    /// `Resources`
    public var resources: ResourcesAPI { ResourcesAPI(client: client) }

    /// `Server`
    public var server: ServerAPI { ServerAPI(client: client) }

    /// `Subscriptions`
    public var subscriptions: SubscriptionsAPI { SubscriptionsAPI(client: client) }

    /// `SystemHealth`
    public var health: SystemHealthAPI { SystemHealthAPI(client: client) }

    /// `Tasks`
    public var tasks: TasksAPI { TasksAPI(client: client) }

    /// `Transfer`
    public var transfer: TransferAPI { TransferAPI(client: client) }

    /// `Upgrade`
    public var upgrade: UpgradeAPI { UpgradeAPI(client: client) }

    /// `Webhook`
    public var webhook: WebhookAPI { WebhookAPI(client: client) }

    /// `config_302`
    public var config302: Config302API { Config302API(client: client) }

    /// `media_organize`
    public var organize: MediaOrganizeAPI { MediaOrganizeAPI(client: client) }

    /// `public`
    public var publicResources: PublicAPI { PublicAPI(client: client) }

    /// `strm`
    public var strm: StrmAPI { StrmAPI(client: client) }

    /// `untagged`
    public var meta: MetaAPI { MetaAPI(client: client) }

}
