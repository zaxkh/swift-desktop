# AGENTS.md - Mattermost Native macOS App

## Project Overview

This repository now contains only the native macOS Mattermost Desktop rewrite. It is a SwiftUI/AppKit/WebKit application targeting macOS 14 Sonoma and later.

Electron, Node, webpack, Playwright E2E, and cross-platform packaging are intentionally removed from this fork.

## Architecture

- `App/` - SwiftUI app entry and AppKit lifecycle integration.
- `Models/` - domain models such as `MattermostServer` and `MattermostViewState`.
- `Stores/` - observable app state and persistence orchestration.
- `Services/` - native integrations and boundaries:
  - `WebViewPool` owns stable `WKWebView` instances.
  - `WebViewCoordinator` handles `WKNavigationDelegate` and `WKUIDelegate` behavior.
  - `DesktopBridge`, `DesktopAPIUserScript`, and `DesktopAPIMessageRouter` implement the JavaScript/native bridge.
  - `URLPolicyService` centralizes internal, external, and deep-link URL decisions.
  - `NotificationService`, `BadgeService`, `LoginItemService`, `StatusItemService`, and `KeychainService` wrap macOS APIs.
- `Views/` - focused SwiftUI views for the shell, settings, tabs, and sheets.
- `Resources/` - `Info.plist` and app entitlements.

## Development Commands

| Command | Purpose |
|---|---|
| `xcodegen generate` | Regenerate `Mattermost.xcodeproj` from `project.yml` |
| `make generate` | Same as above |
| `make build` | Debug build into `/private/tmp/MattermostDerivedData` |
| `make clean` | Remove local derived data |

## Code Conventions

- Every source file starts with the Mattermost copyright header.
- Prefer SwiftUI and Observation for UI state.
- Use AppKit only for macOS-specific behaviors SwiftUI does not cover cleanly.
- Keep business rules in stores/services, not in SwiftUI `body` implementations.
- Keep `WKWebView` ownership out of SwiftUI views. SwiftUI represents state; `WebViewPool` owns web view lifetime.
- Keep native API boundaries small and testable with protocols where behavior has meaningful substitution points.
- Prefer explicit dependency injection through the app composition root over global singletons.
- Keep views small. Extract meaningful sections into dedicated `View` types instead of large computed view helpers.
- Do not reintroduce Electron, npm, webpack, or TypeScript infrastructure.

## Build Notes

The project uses XcodeGen as the source of truth for the Xcode project. If `project.yml` changes, regenerate `Mattermost.xcodeproj`.

The normal verification command is:

```sh
xcodebuild -project Mattermost.xcodeproj -scheme Mattermost -configuration Debug -derivedDataPath /private/tmp/MattermostDerivedData build
```

Some sandboxed automation environments cannot run Swift macro/plugin compilation. In that case, rerun the same build outside the command sandbox.
