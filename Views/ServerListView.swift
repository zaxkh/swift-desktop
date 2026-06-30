// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import SwiftUI

struct ServerListView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var servers = model.servers

        List(model.servers.items, selection: $servers.currentServerID) { server in
            ServerRow(server: server)
                .tag(server.id)
                .contextMenu {
                    Button("Edit Server...") {
                        edit(server)
                    }
                    Button("Remove Server", role: .destructive) {
                        remove(server)
                    }
                    .disabled(server.isPredefined)
                }
        }
        .navigationTitle("Servers")
        .safeAreaInset(edge: .bottom) {
            AddServerButton(action: addServer)
        }
    }

    private func addServer() {
        model.servers.presentAddServer()
    }

    private func edit(_ server: MattermostServer) {
        model.servers.presentEditServer(server)
    }

    private func remove(_ server: MattermostServer) {
        model.removeServer(server)
    }
}

private struct ServerRow: View {
    let server: MattermostServer

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(server.name.isEmpty ? server.displayURL : server.name)
                    .lineLimit(1)
                Text(server.displayURL)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: "server.rack")
        }
        .padding(.vertical, 3)
    }
}

private struct AddServerButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Add Server", systemImage: "plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .padding()
    }
}
