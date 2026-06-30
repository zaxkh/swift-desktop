// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import Foundation
import Observation

struct AppBadgeState: Equatable {
    var hasExpiredSession = false
    var mentionCount = 0
    var hasUnread = false
}

@MainActor
@Observable
final class MattermostViewState: Identifiable {
    enum Kind: Codable {
        case tab
        case window
    }

    enum LoadStatus: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    let id = UUID()
    let serverID: UUID
    var kind: Kind
    var title: String
    var initialPath: String?
    var mentionCount = 0
    var hasUnread = false
    var sessionExpired = false
    var currentURL: URL?
    var pendingNavigationURL: URL?
    var canGoBack = false
    var canGoForward = false
    var loadStatus: LoadStatus = .idle

    init(serverID: UUID, kind: Kind = .tab, title: String = "", initialPath: String? = nil) {
        self.serverID = serverID
        self.kind = kind
        self.title = title
        self.initialPath = initialPath
    }
}
