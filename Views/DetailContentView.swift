// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import SwiftUI

struct DetailContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            if let view = model.views.activeView(for: model.servers.currentServerID) {
                ActiveMattermostView(view: view)
            } else {
                EmptyServerView(addServer: addServer)
            }
        }
    }

    private func addServer() {
        model.servers.presentAddServer()
    }
}

private struct ActiveMattermostView: View {
    let view: MattermostViewState

    var body: some View {
        VStack(spacing: 0) {
            NativeTabBar(serverID: view.serverID)
            Divider()
            MattermostWebView(viewState: view)
        }
        .navigationTitle(view.title.isEmpty ? "Mattermost" : view.title)
    }
}

private struct EmptyServerView: View {
    let addServer: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Add a Mattermost server", systemImage: "server.rack")
        } description: {
            Text("Configure a server to start using the native macOS shell.")
        } actions: {
            Button("Add Server", action: addServer)
                .buttonStyle(.borderedProminent)
        }
    }
}
