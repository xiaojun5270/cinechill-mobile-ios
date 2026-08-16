// Generated from CineChill OpenAPI (v1.0.0.43). Do not edit by hand.
// 由 CineChill OpenAPI 自动生成，请勿手工修改。

import Foundation

/// `DockerManager` 分组，共 20 个接口。
public struct DockerAPI: Sendable {
    let client: APIClient

    init(client: APIClient) { self.client = client }

    /// List Containers
    /// `GET /api/docker/containers`
    @discardableResult
    public func listContainers() async throws -> JSONValue {
        try await client.send(.get, "/api/docker/containers", query: nil)
    }

    /// Check Container Updates
    /// `POST /api/docker/containers/check_updates`
    @discardableResult
    public func checkContainerUpdates(_ body: CheckUpdatesPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/docker/containers/check_updates", query: nil, body: body)
    }

    /// Container Action
    /// `POST /api/docker/containers/{container_id}/action`
    @discardableResult
    public func containerAction(containerId: String, _ body: ContainerActionPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/docker/containers/\(Path.escape(containerId))/action", query: nil, body: body)
    }

    /// Set Container Auto Restart
    /// `POST /api/docker/containers/{container_id}/auto_restart`
    @discardableResult
    public func setContainerAutoRestart(containerId: String, _ body: ScheduledRestartPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/docker/containers/\(Path.escape(containerId))/auto_restart", query: nil, body: body)
    }

    /// Set Container Auto Update
    /// `POST /api/docker/containers/{container_id}/auto_update`
    @discardableResult
    public func setContainerAutoUpdate(containerId: String, _ body: AutoUpdatePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/docker/containers/\(Path.escape(containerId))/auto_update", query: nil, body: body)
    }

    /// Set Container Compose Image
    /// `POST /api/docker/containers/{container_id}/compose_image`
    @discardableResult
    public func setContainerComposeImage(containerId: String, _ body: ComposeImagePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/docker/containers/\(Path.escape(containerId))/compose_image", query: nil, body: body)
    }

    /// Set Container Ignore Update
    /// `POST /api/docker/containers/{container_id}/ignore_update`
    @discardableResult
    public func setContainerIgnoreUpdate(containerId: String, _ body: IgnoreUpdatePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/docker/containers/\(Path.escape(containerId))/ignore_update", query: nil, body: body)
    }

    /// Container Logs
    /// `GET /api/docker/containers/{container_id}/logs`
    @discardableResult
    public func containerLogs(containerId: String, tail: Int? = nil) async throws -> JSONValue {
        try await client.send(.get, "/api/docker/containers/\(Path.escape(containerId))/logs", query: ["tail": Query.value(tail)])
    }

    /// Set Container Scheduled Restart
    /// `POST /api/docker/containers/{container_id}/scheduled_restart`
    @discardableResult
    public func setContainerScheduledRestart(containerId: String, _ body: ScheduledRestartPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/docker/containers/\(Path.escape(containerId))/scheduled_restart", query: nil, body: body)
    }

    /// Resolve Container Icon
    /// `POST /api/docker/icons/resolve`
    @discardableResult
    public func resolveContainerIcon(_ body: ResolveIconPayload) async throws -> JSONValue {
        try await client.send(.post, "/api/docker/icons/resolve", query: nil, body: body)
    }

    /// List Images
    /// `GET /api/docker/images`
    @discardableResult
    public func listImages() async throws -> JSONValue {
        try await client.send(.get, "/api/docker/images", query: nil)
    }

    /// Prune Untagged Images
    /// `POST /api/docker/images/prune_untagged`
    @discardableResult
    public func pruneUntaggedImages() async throws -> JSONValue {
        try await client.send(.post, "/api/docker/images/prune_untagged", query: nil)
    }

    /// Prune Unused Images
    /// `POST /api/docker/images/prune_unused`
    @discardableResult
    public func pruneUnusedImages() async throws -> JSONValue {
        try await client.send(.post, "/api/docker/images/prune_unused", query: nil)
    }

    /// Pull Image
    /// `POST /api/docker/images/pull`
    @discardableResult
    public func pullImage(_ body: PullImagePayload) async throws -> JSONValue {
        try await client.send(.post, "/api/docker/images/pull", query: nil, body: body)
    }

    /// Delete Image
    /// `DELETE /api/docker/images/{image_id}`
    @discardableResult
    public func deleteImage(imageId: String, force: Bool? = nil) async throws -> JSONValue {
        try await client.send(.delete, "/api/docker/images/\(Path.escape(imageId))", query: ["force": Query.value(force)])
    }

    /// Get Registry Auth
    /// `GET /api/docker/registry_auth`
    @discardableResult
    public func getRegistryAuth() async throws -> JSONValue {
        try await client.send(.get, "/api/docker/registry_auth", query: nil)
    }

    /// Save Registry Auth
    /// `PUT /api/docker/registry_auth`
    @discardableResult
    public func saveRegistryAuth(_ body: RegistryAuthPayload) async throws -> JSONValue {
        try await client.send(.put, "/api/docker/registry_auth", query: nil, body: body)
    }

    /// Delete Registry Auth
    /// `DELETE /api/docker/registry_auth`
    @discardableResult
    public func deleteRegistryAuth() async throws -> JSONValue {
        try await client.send(.delete, "/api/docker/registry_auth", query: nil)
    }

    /// Docker Status
    /// `GET /api/docker/status`
    @discardableResult
    public func dockerStatus() async throws -> JSONValue {
        try await client.send(.get, "/api/docker/status", query: nil)
    }

    /// Get Update Task
    /// `GET /api/docker/update_tasks/{run_id}`
    @discardableResult
    public func getUpdateTask(runId: String) async throws -> JSONValue {
        try await client.send(.get, "/api/docker/update_tasks/\(Path.escape(runId))", query: nil)
    }

}
