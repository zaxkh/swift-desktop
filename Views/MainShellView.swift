// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import SwiftUI

struct MainShellView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var servers = model.servers

        NavigationSplitView {
            ServerListView()
        } detail: {
            DetailContentView()
        }
        .sheet(item: $servers.editor) { editor in
            ServerEditorSheet(editor: editor)
                .environment(model)
        }
        .alert("Mattermost", isPresented: Binding(
            get: { model.servers.lastError != nil },
            set: { if !$0 { model.servers.lastError = nil } }
        )) {
            Button("OK", role: .cancel) {
                model.servers.lastError = nil
            }
        } message: {
            Text(model.servers.lastError ?? "")
        }
    }
}
