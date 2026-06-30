// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import Foundation

struct MattermostServer: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var url: URL
    var isPredefined = false
    var isLoggedIn = false

    var displayURL: String {
        url.absoluteString
    }
}
