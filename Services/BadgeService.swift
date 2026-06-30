// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import AppKit

@MainActor
final class BadgeService {
    func update(from state: AppBadgeState, showUnreadBadge: Bool) {
        let badge: String
        if state.mentionCount > 0 {
            badge = state.mentionCount > 99 ? "99+" : "\(state.mentionCount)"
        } else if showUnreadBadge && state.hasUnread {
            badge = "•"
        } else if state.hasExpiredSession {
            badge = "!"
        } else {
            badge = ""
        }

        NSApplication.shared.dockTile.badgeLabel = badge
    }
}
