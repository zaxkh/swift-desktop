// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import AppKit
import Foundation
import WebKit

@MainActor
protocol DesktopAPIMessageRouting: AnyObject {
    func bind(to webView: WKWebView)
    func handle(name: String, payload: Any?) async -> Any
}

@MainActor
final class DesktopAPIMessageRouter: DesktopAPIMessageRouting {
    private weak var appModel: AppModel?
    private weak var viewState: MattermostViewState?
    private weak var webView: WKWebView?

    init(appModel: AppModel, viewState: MattermostViewState) {
        self.appModel = appModel
        self.viewState = viewState
    }

    func bind(to webView: WKWebView) {
        self.webView = webView
    }

    func handle(name: String, payload: Any?) async -> Any {
        guard let appModel, let viewState else {
            return DesktopAPIResponse.error("bridge_released")
        }

        switch name {
        case "getAppInfo":
            return ["name": "Mattermost", "version": Bundle.main.appVersion]
        case "reactAppInitialized":
            viewState.loadStatus = .ready
            return DesktopAPIResponse.success
        case "setSessionExpired":
            updateSessionExpired(payload, viewState: viewState, appModel: appModel)
            return DesktopAPIResponse.success
        case "setLoggedIn":
            updateLoggedIn(payload, viewState: viewState, appModel: appModel)
            return DesktopAPIResponse.success
        case "sendNotification":
            return await appModel.notifications.send(payload)
        case "setUnreadsAndMentions":
            let result = appModel.views.updateUnreads(viewID: viewState.id, payload: payload)
            appModel.updateBadge()
            return result
        case "requestBrowserHistoryStatus":
            return ["canGoBack": webView?.canGoBack ?? false, "canGoForward": webView?.canGoForward ?? false]
        case "browserHistoryPush":
            pushBrowserHistory(payload, viewState: viewState, appModel: appModel)
            return DesktopAPIResponse.success
        case "updateTheme":
            return DesktopAPIResponse.success
        case "getDarkMode":
            return NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        case "openPopout":
            return appModel.webViews.openPopout(payload: payload, from: viewState, appModel: appModel)
        case "getDesktopSources":
            return []
        case "openLink":
            openLink(payload, appModel: appModel)
            return DesktopAPIResponse.success
        case "closeWindow":
            webView?.window?.close()
            return DesktopAPIResponse.success
        case "joinCall":
            return [
                "callID": (payload as? [String: Any])?["callID"] as? String ?? "",
                "sessionID": UUID().uuidString,
            ]
        default:
            return ["status": "unsupported", "method": name]
        }
    }

    private func updateSessionExpired(_ payload: Any?, viewState: MattermostViewState, appModel: AppModel) {
        guard let payload = payload as? [String: Any] else {
            return
        }
        viewState.sessionExpired = payload["isExpired"] as? Bool ?? false
        appModel.updateBadge()
    }

    private func updateLoggedIn(_ payload: Any?, viewState: MattermostViewState, appModel: AppModel) {
        guard let payload = payload as? [String: Any],
              let index = appModel.servers.items.firstIndex(where: { $0.id == viewState.serverID }) else {
            return
        }
        appModel.servers.items[index].isLoggedIn = payload["isLoggedIn"] as? Bool ?? false
        appModel.servers.save()
    }

    private func pushBrowserHistory(_ payload: Any?, viewState: MattermostViewState, appModel: AppModel) {
        guard let path = (payload as? [String: Any])?["path"] as? String,
              let server = appModel.servers.server(id: viewState.serverID),
              let url = URL(string: path, relativeTo: server.url)?.absoluteURL else {
            return
        }
        viewState.pendingNavigationURL = url
    }

    private func openLink(_ payload: Any?, appModel: AppModel) {
        guard let rawURL = (payload as? [String: Any])?["url"] as? String,
              let url = URL(string: rawURL) else {
            return
        }
        appModel.handleDeepLink(url)
    }
}

private enum DesktopAPIResponse {
    static let success: [String: Any] = ["status": "success"]

    static func error(_ reason: String) -> [String: Any] {
        ["status": "error", "reason": reason]
    }
}
