// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import Foundation
import Observation

@MainActor
@Observable
final class ViewStore {
    var items: [MattermostViewState] = []
    var activeViewIDsByServer: [UUID: UUID] = [:]

    var appBadgeState: AppBadgeState {
        AppBadgeState(
            hasExpiredSession: items.contains { $0.sessionExpired },
            mentionCount: items.reduce(0) { $0 + $1.mentionCount },
            hasUnread: items.contains { $0.hasUnread }
        )
    }

    func ensurePrimaryTabs(for servers: [MattermostServer]) {
        let serverIDs = Set(servers.map(\.id))
        items.removeAll { !serverIDs.contains($0.serverID) }
        activeViewIDsByServer = activeViewIDsByServer.filter { serverIDs.contains($0.key) }

        for server in servers where tabs(for: server.id).isEmpty {
            let view = MattermostViewState(serverID: server.id, kind: .tab, title: server.name)
            items.append(view)
            activeViewIDsByServer[server.id] = view.id
        }
    }

    func tabs(for serverID: UUID) -> [MattermostViewState] {
        items.filter { $0.serverID == serverID && $0.kind == .tab }
    }

    func activeView(for serverID: UUID?) -> MattermostViewState? {
        guard let serverID else {
            return nil
        }
        if let activeViewID = activeViewIDsByServer[serverID],
           let view = items.first(where: { $0.id == activeViewID }) {
            return view
        }
        return tabs(for: serverID).first
    }

    @discardableResult
    func createTab(serverID: UUID, title: String, initialPath: String? = nil) -> MattermostViewState {
        let view = MattermostViewState(serverID: serverID, kind: .tab, title: title, initialPath: initialPath)
        items.append(view)
        activeViewIDsByServer[serverID] = view.id
        return view
    }

    @discardableResult
    func createWindow(serverID: UUID, title: String, initialPath: String? = nil) -> MattermostViewState {
        let view = MattermostViewState(serverID: serverID, kind: .window, title: title, initialPath: initialPath)
        items.append(view)
        return view
    }

    func setActiveView(_ viewID: UUID, for serverID: UUID) {
        activeViewIDsByServer[serverID] = viewID
    }

    func close(viewID: UUID) {
        guard let view = items.first(where: { $0.id == viewID }) else {
            return
        }

        items.removeAll { $0.id == viewID }
        if activeViewIDsByServer[view.serverID] == viewID {
            activeViewIDsByServer[view.serverID] = tabs(for: view.serverID).first?.id
        }
    }

    func renamePrimaryTab(serverID: UUID, title: String) {
        tabs(for: serverID).first?.title = title
    }

    func updateUnreads(viewID: UUID, payload: Any?) -> [String: Any] {
        guard let view = items.first(where: { $0.id == viewID }) else {
            return ["status": "error", "reason": "view_not_found"]
        }
        if let payload = payload as? [String: Any] {
            view.hasUnread = payload["isUnread"] as? Bool ?? view.hasUnread
            if let mentionCount = payload["mentionCount"] as? Int {
                view.mentionCount = mentionCount
            } else if let mentionCount = payload["mentionCount"] as? Double {
                view.mentionCount = Int(mentionCount)
            }
        }
        return ["status": "success"]
    }

    @discardableResult
    func open(url: URL, matching servers: [MattermostServer]) -> MattermostViewState? {
        guard let match = matchedServer(for: url, servers: servers) else {
            return nil
        }

        let targetURL = nativeURL(url, resolvedAgainst: match)
        let view = activeView(for: match.id) ?? createTab(serverID: match.id, title: match.name)
        view.pendingNavigationURL = targetURL
        activeViewIDsByServer[match.id] = view.id
        return view
    }

    func loadingURL(for view: MattermostViewState, servers: [MattermostServer]) -> URL? {
        guard let server = servers.first(where: { $0.id == view.serverID }) else {
            return nil
        }
        guard let initialPath = view.initialPath, !initialPath.isEmpty else {
            return server.url
        }
        return URL(string: initialPath, relativeTo: server.url)?.absoluteURL
    }

    private func matchedServer(for url: URL, servers: [MattermostServer]) -> MattermostServer? {
        if url.scheme?.lowercased() == "mattermost" {
            return servers.first { $0.url.host?.caseInsensitiveCompare(url.host ?? "") == .orderedSame }
        }

        return servers.first { server in
            guard server.url.host?.caseInsensitiveCompare(url.host ?? "") == .orderedSame else {
                return false
            }
            let configuredPath = server.url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !configuredPath.isEmpty else {
                return true
            }
            return url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).hasPrefix(configuredPath)
        }
    }

    private func nativeURL(_ url: URL, resolvedAgainst server: MattermostServer) -> URL {
        guard url.scheme?.lowercased() == "mattermost" else {
            return url
        }

        var components = URLComponents(url: server.url, resolvingAgainstBaseURL: false)
        components?.path = url.path.isEmpty ? server.url.path : url.path
        components?.query = url.query
        components?.fragment = url.fragment
        return components?.url ?? server.url
    }
}
