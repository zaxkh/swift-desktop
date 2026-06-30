# Native macOS Mattermost Manual Testing Plan

| Scenario | Expected Result | Edge Cases |
|---|---|---|
| First launch | Empty native shell appears and Add Server is available. | No network, malformed URL, app relaunched after quitting. |
| Add/edit/remove servers | Server list persists in order and primary tab is created per server. | Duplicate URL, predefined server cannot edit, removing current server selects next server. |
| Login/session | WKWebView preserves cookies through app relaunch. | Logout clears logged-in state, server with custom path. |
| Multi-server switching | Switching sidebar servers restores that server's active tab and web state. | 10+ servers, slow server, server unreachable. |
| Tabs/windows | New tab, close tab, and popout window keep independent WKWebView state. | Last tab cannot close, popout from plugin/calls route. |
| Deep links | `mattermost://` and matching HTTPS links route into the configured server. | Unknown server opens Add Server, custom path servers. |
| Notifications | Native notification appears and clicking routes to the URL. | Silent notification, notification permission denied. |
| Badges | Dock badge shows mention count, unread dot, or expired marker. | Mention count over 99, unread badge disabled. |
| Background/status item | Closing the last window keeps app alive and status item can reopen it. | Status item disabled, Quit from menu bar. |
| Plugins | Plugin pages and OAuth popups open in a native popup window or external browser based on URL policy. | `about:blank`, managed resources, blocked custom protocol. |
| Calls/media | Camera and microphone prompts appear when the web app requests media. | Permission denied, screen sharing source list currently returns empty. |
| Security | External URLs open in the default browser; invalid URLs are blocked. | Self-signed certificate flow, mailto/tel links. |
| Performance | Idle CPU/memory and bundle size are lower than Electron baseline. | Long-running session, repeated tab switching, plugin popups. |
