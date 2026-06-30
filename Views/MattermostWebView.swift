// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import SwiftUI
import WebKit

struct MattermostWebView: NSViewRepresentable {
    @Environment(AppModel.self) private var model
    let viewState: MattermostViewState

    func makeNSView(context: Context) -> WKWebView {
        model.webViews.webView(for: viewState, appModel: model)
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        model.webViews.applyPendingNavigation(for: viewState, webView: webView)
    }
}
