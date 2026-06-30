// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Form {
            Section("General") {
                Toggle("Show Mattermost in the menu bar", isOn: Binding(
                    get: { model.servers.preferences.showStatusItem },
                    set: { model.setShowStatusItem($0) }
                ))

                Toggle("Start Mattermost on login", isOn: Binding(
                    get: { model.servers.preferences.autostart },
                    set: { model.setAutostart($0) }
                ))

                Toggle("Open in full screen", isOn: Binding(
                    get: { model.servers.preferences.startInFullScreen },
                    set: {
                        model.servers.preferences.startInFullScreen = $0
                        model.servers.save()
                    }
                ))
            }

            Section("Notifications") {
                Toggle("Show unread badge on Dock icon", isOn: Binding(
                    get: { model.servers.preferences.showUnreadBadge },
                    set: { model.setShowUnreadBadge($0) }
                ))
            }

            Section("Appearance") {
                Toggle("Synchronize native shell with server theme", isOn: Binding(
                    get: { model.servers.preferences.themeSyncing },
                    set: {
                        model.servers.preferences.themeSyncing = $0
                        model.servers.save()
                    }
                ))
            }

            Section("Servers") {
                ForEach(model.servers.items) { server in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(server.name)
                            Text(server.displayURL)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        Spacer()
                        Button("Edit") {
                            model.servers.presentEditServer(server)
                        }
                        .disabled(server.isPredefined)
                    }
                }

                Button {
                    model.servers.presentAddServer()
                } label: {
                    Label("Add Server", systemImage: "plus")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 620, height: 520)
    }
}
