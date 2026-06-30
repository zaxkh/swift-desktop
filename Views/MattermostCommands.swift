// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import SwiftUI
import WebKit

@MainActor
struct MattermostCommands: Commands {
    let model: AppModel

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Tab") {
                if let serverID = model.servers.currentServerID {
                    model.createTab(for: serverID)
                }
            }
            .keyboardShortcut("t", modifiers: [.command])
            .disabled(model.servers.currentServerID == nil)

            Button("Add Server...") {
                model.servers.presentAddServer()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        CommandMenu("Server") {
            ForEach(Array(model.servers.items.enumerated()), id: \.element.id) { index, server in
                if index < 9 {
                    serverButton(server)
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [.command])
                } else {
                    serverButton(server)
                }
            }
        }

        CommandMenu("Navigation") {
            Button("Back") {
                activeWebView?.goBack()
            }
            .keyboardShortcut("[", modifiers: [.command])
            .disabled(activeWebView?.canGoBack != true)

            Button("Forward") {
                activeWebView?.goForward()
            }
            .keyboardShortcut("]", modifiers: [.command])
            .disabled(activeWebView?.canGoForward != true)

            Button("Reload") {
                activeWebView?.reload()
            }
            .keyboardShortcut("r", modifiers: [.command])
        }
    }

    private var activeWebView: WKWebView? {
        guard let view = model.views.activeView(for: model.servers.currentServerID) else {
            return nil
        }
        return model.webViews.webView(for: view, appModel: model)
    }

    private func serverButton(_ server: MattermostServer) -> some View {
        Button(server.name) {
            model.servers.currentServerID = server.id
            model.servers.save()
        }
    }
}
