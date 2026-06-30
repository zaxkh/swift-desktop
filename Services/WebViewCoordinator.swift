// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import AppKit
import WebKit

@MainActor
final class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    weak var appModel: AppModel?
    weak var viewState: MattermostViewState?

    private let bridge: DesktopBridge
    private var pluginWindows: [NSWindow] = []

    init(appModel: AppModel, viewState: MattermostViewState, bridge: DesktopBridge) {
        self.appModel = appModel
        self.viewState = viewState
        self.bridge = bridge
        super.init()
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        viewState?.loadStatus = .loading
        viewState?.currentURL = webView.url
        updateHistoryStatus(webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        viewState?.loadStatus = .ready
        viewState?.currentURL = webView.url
        if let title = webView.title, !title.isEmpty {
            viewState?.title = MattermostPageTitleParser.channelTitle(from: title)
        }
        updateHistoryStatus(webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        viewState?.loadStatus = .failed(error.localizedDescription)
        updateHistoryStatus(webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        viewState?.loadStatus = .failed(error.localizedDescription)
        updateHistoryStatus(webView)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        viewState?.loadStatus = .loading
        webView.reload()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let appModel, let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let server = appModel.servers.server(id: viewState?.serverID)
        switch appModel.urlPolicy.decision(for: url, server: server) {
        case .allow:
            decisionHandler(.allow)
        case .handleDeepLink:
            appModel.handleDeepLink(url)
            decisionHandler(.cancel)
        case .openExternal:
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        case .block:
            decisionHandler(.cancel)
        }
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame?.isMainFrame != true else {
            return nil
        }

        if shouldOpenExternally(navigationAction.request.url) {
            if let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
            }
            return nil
        }

        return openPluginPopup(configuration: configuration, parentWebView: webView)
    }

    func webViewDidClose(_ webView: WKWebView) {
        webView.window?.close()
    }

    private func shouldOpenExternally(_ url: URL?) -> Bool {
        guard let url,
              let appModel,
              let server = appModel.servers.server(id: viewState?.serverID) else {
            return false
        }
        return appModel.urlPolicy.decision(for: url, server: server) == .openExternal
    }

    private func openPluginPopup(configuration: WKWebViewConfiguration, parentWebView: WKWebView) -> WKWebView {
        let popupWebView = WKWebView(frame: .zero, configuration: configuration)
        popupWebView.customUserAgent = parentWebView.customUserAgent
        popupWebView.navigationDelegate = self
        popupWebView.uiDelegate = self

        let popupWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        popupWindow.title = "Mattermost"
        popupWindow.center()
        popupWindow.contentView = popupWebView
        popupWindow.makeKeyAndOrderFront(nil)
        pluginWindows.append(popupWindow)

        return popupWebView
    }

    private func updateHistoryStatus(_ webView: WKWebView) {
        viewState?.canGoBack = webView.canGoBack
        viewState?.canGoForward = webView.canGoForward
        bridge.emit("browserHistoryStatusUpdated", args: [webView.canGoBack, webView.canGoForward])
    }
}

private enum MattermostPageTitleParser {
    static func channelTitle(from title: String) -> String {
        var channelTitle = title
        if let separatorRange = channelTitle.range(of: " - ", options: []) {
            channelTitle = String(channelTitle[..<separatorRange.lowerBound])
        }
        if channelTitle.hasPrefix("("), let closeParen = channelTitle.firstIndex(of: ")") {
            channelTitle = channelTitle[channelTitle.index(after: closeParen)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return channelTitle.isEmpty ? title : channelTitle
    }
}
