// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import SwiftUI

@main
struct MattermostApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup("Mattermost") {
            MainShellView()
                .environment(model)
                .onOpenURL { url in
                    model.handleDeepLink(url)
                }
                .task {
                    await model.start()
                }
        }
        .defaultSize(width: 1280, height: 860)
        .commands {
            MattermostCommands(model: model)
        }

        Settings {
            SettingsView()
                .environment(model)
        }
    }
}
