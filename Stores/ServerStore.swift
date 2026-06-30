// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import Foundation
import Observation

enum ServerStoreError: LocalizedError {
    case invalidURL
    case duplicateServer
    case predefinedServer
    case missingServer

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Enter a valid Mattermost server URL."
        case .duplicateServer:
            return "That Mattermost server is already configured."
        case .predefinedServer:
            return "Predefined servers cannot be edited."
        case .missingServer:
            return "The selected server no longer exists."
        }
    }
}

struct AppPreferences: Codable, Equatable {
    var showStatusItem = true
    var minimizeToMenuBar = true
    var autostart = false
    var showUnreadBadge = true
    var themeSyncing = true
    var startInFullScreen = false
}

struct ServerEditorState: Identifiable, Equatable {
    enum Mode: Equatable {
        case add
        case edit(UUID)
    }

    let id = UUID()
    var mode: Mode
    var title: String
    var name: String
    var urlString: String
}

private struct AppConfiguration: Codable {
    var version = 1
    var servers: [MattermostServer] = []
    var currentServerID: UUID?
    var preferences = AppPreferences()
}

@MainActor
@Observable
final class ServerStore {
    var items: [MattermostServer] = []
    var currentServerID: UUID?
    var preferences = AppPreferences()
    var editor: ServerEditorState?
    var lastError: String?

    private let configurationURL: URL

    init(configurationURL: URL? = nil) {
        if let configurationURL {
            self.configurationURL = configurationURL
        } else {
            self.configurationURL = Self.defaultConfigurationURL()
        }
    }

    var currentServer: MattermostServer? {
        guard let currentServerID else {
            return nil
        }
        return server(id: currentServerID)
    }

    func server(id: UUID?) -> MattermostServer? {
        guard let id else {
            return nil
        }
        return items.first { $0.id == id }
    }

    func load() {
        do {
            let data = try Data(contentsOf: configurationURL)
            let config = try JSONDecoder().decode(AppConfiguration.self, from: data)
            items = config.servers
            preferences = config.preferences
            currentServerID = config.currentServerID ?? items.first?.id
        } catch CocoaError.fileReadNoSuchFile {
            items = []
            currentServerID = nil
            preferences = AppPreferences()
        } catch {
            lastError = "Unable to load configuration: \(error.localizedDescription)"
        }
    }

    func save() {
        let config = AppConfiguration(servers: items, currentServerID: currentServerID, preferences: preferences)
        do {
            try FileManager.default.createDirectory(
                at: configurationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(config).write(to: configurationURL, options: .atomic)
        } catch {
            lastError = "Unable to save configuration: \(error.localizedDescription)"
        }
    }

    func presentAddServer(prefillURL: String? = nil) {
        editor = ServerEditorState(
            mode: .add,
            title: "Add Server",
            name: "",
            urlString: prefillURL ?? ""
        )
    }

    func presentEditServer(_ server: MattermostServer) {
        editor = ServerEditorState(
            mode: .edit(server.id),
            title: "Edit Server",
            name: server.name,
            urlString: server.url.absoluteString
        )
    }

    @discardableResult
    func addServer(name: String, urlString: String) throws -> MattermostServer {
        let url = try Self.normalizedServerURL(from: urlString)
        guard !items.contains(where: { Self.sameServer($0.url, url) }) else {
            throw ServerStoreError.duplicateServer
        }

        let server = MattermostServer(name: name.trimmingCharacters(in: .whitespacesAndNewlines), url: url)
        items.append(server)
        currentServerID = server.id
        return server
    }

    func editServer(id: UUID, name: String, urlString: String) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw ServerStoreError.missingServer
        }
        guard !items[index].isPredefined else {
            throw ServerStoreError.predefinedServer
        }

        let url = try Self.normalizedServerURL(from: urlString)
        guard !items.contains(where: { $0.id != id && Self.sameServer($0.url, url) }) else {
            throw ServerStoreError.duplicateServer
        }

        items[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        items[index].url = url
    }

    func removeServer(id: UUID) {
        items.removeAll { $0.id == id }
        if currentServerID == id {
            currentServerID = items.first?.id
        }
        save()
    }

    static func normalizedServerURL(from rawValue: String) throws -> URL {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"

        guard var components = URLComponents(string: withScheme),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              components.host?.isEmpty == false else {
            throw ServerStoreError.invalidURL
        }

        components.scheme = scheme
        if components.path.isEmpty {
            components.path = "/"
        }

        guard let url = components.url else {
            throw ServerStoreError.invalidURL
        }
        return url
    }

    private static func sameServer(_ lhs: URL, _ rhs: URL) -> Bool {
        lhs.scheme?.lowercased() == rhs.scheme?.lowercased() &&
            lhs.host?.lowercased() == rhs.host?.lowercased() &&
            lhs.port == rhs.port &&
            lhs.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ==
            rhs.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private static func defaultConfigurationURL() -> URL {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return applicationSupport
            .appendingPathComponent("Mattermost", isDirectory: true)
            .appendingPathComponent("config.json")
    }
}
