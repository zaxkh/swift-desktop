// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import AppKit
import Foundation
import WebKit

@MainActor
final class WebViewPool {
    private struct Entry {
        let webView: WKWebView
        let coordinator: WebViewCoordinator
        let bridge: DesktopBridge
    }

    private let processPool = WKProcessPool()
    private var entries: [UUID: Entry] = [:]
    private var popoutWindows: [UUID: NSWindow] = [:]

    func webView(for viewState: MattermostViewState, appModel: AppModel) -> WKWebView {
        if let entry = entries[viewState.id] {
            entry.coordinator.appModel = appModel
            entry.coordinator.viewState = viewState
            return entry.webView
        }

        let router = DesktopAPIMessageRouter(appModel: appModel, viewState: viewState)
        let bridge = DesktopBridge(router: router)
        let configuration = makeConfiguration(bridge: bridge)
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = userAgent
        bridge.bind(to: webView)

        let coordinator = WebViewCoordinator(appModel: appModel, viewState: viewState, bridge: bridge)
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator

        let entry = Entry(webView: webView, coordinator: coordinator, bridge: bridge)
        entries[viewState.id] = entry

        if let url = appModel.views.loadingURL(for: viewState, servers: appModel.servers.items) {
            viewState.currentURL = url
            viewState.loadStatus = .loading
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func applyPendingNavigation(for viewState: MattermostViewState, webView: WKWebView) {
        guard let url = viewState.pendingNavigationURL else {
            return
        }
        viewState.pendingNavigationURL = nil
        viewState.currentURL = url
        viewState.loadStatus = .loading
        webView.load(URLRequest(url: url))
    }

    func removeView(_ viewID: UUID) {
        entries.removeValue(forKey: viewID)
        if let window = popoutWindows.removeValue(forKey: viewID) {
            window.close()
        }
    }

    func removeViews(forServerID serverID: UUID) {
        let viewIDs = entries
            .filter { $0.value.coordinator.viewState?.serverID == serverID }
            .map(\.key)
        viewIDs.forEach(removeView)
    }

    func openPopout(payload: Any?, from parentView: MattermostViewState, appModel: AppModel) -> String {
        let payload = payload as? [String: Any]
        let path = payload?["path"] as? String
        let title = appModel.servers.server(id: parentView.serverID)?.name ?? "Mattermost"
        let viewState = appModel.views.createWindow(serverID: parentView.serverID, title: title, initialPath: path)
        let webView = webView(for: viewState, appModel: appModel)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.center()
        window.contentView = webView
        window.makeKeyAndOrderFront(nil)
        popoutWindows[viewState.id] = window

        return viewState.id.uuidString
    }

    private func makeConfiguration(bridge: DesktopBridge) -> WKWebViewConfiguration {
        let userContentController = WKUserContentController()
        userContentController.addUserScript(DesktopAPIUserScript.script)
        userContentController.add(bridge, name: DesktopAPIUserScript.handlerName)

        let configuration = WKWebViewConfiguration()
        configuration.processPool = processPool
        configuration.websiteDataStore = .default()
        configuration.userContentController = userContentController
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        return configuration
    }

    private var userAgent: String {
        let version = Bundle.main.appVersion
        return "MattermostMac/\(version) (Macintosh; macOS)"
    }
}
