// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class AppModel {
    var servers = ServerStore()
    var views = ViewStore()

    @ObservationIgnored let notifications = NotificationService()
    @ObservationIgnored let badges = BadgeService()
    @ObservationIgnored let loginItems = LoginItemService()
    @ObservationIgnored let statusItem = StatusItemService()
    @ObservationIgnored let webViews = WebViewPool()
    @ObservationIgnored let urlPolicy = URLPolicyService()
    @ObservationIgnored let keychain = KeychainService()

    private var hasStarted = false

    func start() async {
        guard !hasStarted else {
            return
        }
        hasStarted = true

        AppDelegate.openURLHandler = { [weak self] url in
            Task { @MainActor in
                self?.handleDeepLink(url)
            }
        }
        notifications.onNotificationURL = { [weak self] url in
            self?.handleDeepLink(url)
        }

        await notifications.requestAuthorization()
        servers.load()
        views.ensurePrimaryTabs(for: servers.items)
        statusItem.configure(appModel: self)
        statusItem.setVisible(servers.preferences.showStatusItem)
        badges.update(from: views.appBadgeState, showUnreadBadge: servers.preferences.showUnreadBadge)
    }

    func handleDeepLink(_ url: URL) {
        if let view = views.open(url: url, matching: servers.items) {
            servers.currentServerID = view.serverID
            servers.save()
        } else {
            servers.presentAddServer(prefillURL: url.host.map { "\($0)\(url.path)" })
        }
    }

    func addServer(name: String, urlString: String) throws {
        let server = try servers.addServer(name: name, urlString: urlString)
        views.ensurePrimaryTabs(for: servers.items)
        servers.currentServerID = server.id
        servers.save()
    }

    func updateServer(editor: ServerEditorState, name: String, urlString: String) throws {
        switch editor.mode {
        case .add:
            try addServer(name: name, urlString: urlString)
        case .edit(let serverID):
            try servers.editServer(id: serverID, name: name, urlString: urlString)
            views.renamePrimaryTab(serverID: serverID, title: name)
            servers.save()
        }
    }

    func removeServer(_ server: MattermostServer) {
        servers.removeServer(id: server.id)
        views.ensurePrimaryTabs(for: servers.items)
        webViews.removeViews(forServerID: server.id)
        badges.update(from: views.appBadgeState, showUnreadBadge: servers.preferences.showUnreadBadge)
    }

    func createTab(for serverID: UUID, initialPath: String? = nil) {
        let view = views.createTab(serverID: serverID, title: servers.server(id: serverID)?.name ?? "Mattermost", initialPath: initialPath)
        views.setActiveView(view.id, for: serverID)
    }

    func closeTab(_ view: MattermostViewState) {
        views.close(viewID: view.id)
        webViews.removeView(view.id)
        badges.update(from: views.appBadgeState, showUnreadBadge: servers.preferences.showUnreadBadge)
    }

    func updateBadge() {
        badges.update(from: views.appBadgeState, showUnreadBadge: servers.preferences.showUnreadBadge)
    }

    func setShowStatusItem(_ isVisible: Bool) {
        servers.preferences.showStatusItem = isVisible
        servers.save()
        statusItem.setVisible(isVisible)
    }

    func setShowUnreadBadge(_ showUnreadBadge: Bool) {
        servers.preferences.showUnreadBadge = showUnreadBadge
        servers.save()
        updateBadge()
    }

    func setAutostart(_ autostart: Bool) {
        servers.preferences.autostart = autostart
        servers.save()
        do {
            if autostart {
                try loginItems.enable()
            } else {
                try loginItems.disable()
            }
        } catch {
            servers.lastError = "Unable to update login item: \(error.localizedDescription)"
        }
    }

    func showMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
