// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import Foundation
import WebKit

final class DesktopBridge: NSObject, WKScriptMessageHandler {
    private let router: DesktopAPIMessageRouting
    private weak var webView: WKWebView?

    init(router: DesktopAPIMessageRouting) {
        self.router = router
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let id = body["id"] as? String,
              let name = body["name"] as? String else {
            return
        }

        Task { @MainActor in
            let result = await router.handle(name: name, payload: body["payload"])
            resolve(id: id, ok: true, value: result)
        }
    }

    @MainActor
    func bind(to webView: WKWebView) {
        self.webView = webView
        router.bind(to: webView)
    }

    @MainActor
    private func resolve(id: String, ok: Bool, value: Any) {
        let idJSON = JSONSerialization.safeJSONString(id)
        let valueJSON = JSONSerialization.safeJSONString(value)
        webView?.evaluateJavaScript("window.__mmNativeResolve(\(idJSON), \(ok ? "true" : "false"), \(valueJSON));")
    }

    @MainActor
    func emit(_ name: String, args: [Any] = []) {
        let nameJSON = JSONSerialization.safeJSONString(name)
        let argsJSON = JSONSerialization.safeJSONString(args)
        webView?.evaluateJavaScript("window.__mmNativeEmit(\(nameJSON), \(argsJSON));")
    }
}
