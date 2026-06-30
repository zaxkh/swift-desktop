// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import Foundation

enum URLPolicyDecision: Equatable {
    case allow
    case openExternal
    case handleDeepLink
    case block
}

struct URLPolicyService {
    func decision(for url: URL, server: MattermostServer?) -> URLPolicyDecision {
        guard let scheme = url.scheme?.lowercased() else {
            return .block
        }

        if scheme == "about" {
            return .allow
        }
        if scheme == "mattermost" {
            return .handleDeepLink
        }
        if ["mailto", "tel"].contains(scheme) {
            return .openExternal
        }
        guard ["http", "https"].contains(scheme) else {
            return .openExternal
        }
        guard let server else {
            return .openExternal
        }
        guard server.url.host?.caseInsensitiveCompare(url.host ?? "") == .orderedSame else {
            return .openExternal
        }

        let serverPath = server.url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if serverPath.isEmpty {
            return .allow
        }
        let urlPath = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return urlPath.hasPrefix(serverPath) ? .allow : .openExternal
    }
}
