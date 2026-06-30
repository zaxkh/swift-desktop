# Mattermost Native Desktop for macOS

This repository is a native macOS rewrite of the Mattermost Desktop app. It replaces Electron with a SwiftUI shell and persistent `WKWebView` instances for Mattermost web content.

The app targets macOS 14 Sonoma and later.

## Goals

- Provide a native macOS Mattermost desktop client with lower overhead than Electron.
- Keep the app shell native: sidebar, tabs, settings, menu commands, Dock badges, notifications, login item support, and status item behavior.
- Preserve Mattermost web app compatibility through an injected `window.desktopAPI` shim.
- Keep the implementation small, explicit, and idiomatic Swift.

## Project Structure

```text
App/          SwiftUI app entry, AppKit app delegate
Models/       Codable and observable domain models
Stores/       App, server, and view state ownership
Services/     WebKit bridge, URL policy, notifications, badges, status item, login item, Keychain
Views/        SwiftUI shell, server list, tabs, settings, sheets
Resources/    Info.plist and entitlements
```

## Development

Generate or refresh the Xcode project:

```sh
xcodegen generate
```

Build:

```sh
xcodebuild -project Mattermost.xcodeproj -scheme Mattermost -configuration Debug -derivedDataPath /private/tmp/MattermostDerivedData build
```

Or use:

```sh
make build
```

## Current Feature Surface

- Native SwiftUI shell with a server sidebar and native tab strip.
- Add, edit, remove, persist, and switch Mattermost servers.
- Persistent `WKWebView` pool per Mattermost view.
- `window.desktopAPI` compatibility shim for app info, notifications, unread state, history, popouts, theme/dark-mode calls, and calls-related stubs.
- Native notifications through `UNUserNotificationCenter`.
- Dock badge aggregation for mentions, unreads, and expired sessions.
- Native status item and login item integration.
- Mattermost URL scheme registration and basic deep-link routing.
- App sandbox, network, camera, microphone, Downloads, and user-selected file entitlements.

## Known Gaps

- Calls and screen sharing currently expose compatibility stubs where native ScreenCaptureKit/WebRTC work is still needed.
- Automatic migration from the Electron `config.json` format is not implemented.
- Release packaging, notarization, Sparkle-style updates, and Mac App Store configuration are intentionally not part of this scaffold yet.
- No unit or integration tests are included by design for this fork stage; use `ManualTestingPlan.md`.
