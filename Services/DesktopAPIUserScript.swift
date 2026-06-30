// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import WebKit

enum DesktopAPIUserScript {
    static let handlerName = "desktopAPI"

    static let script = WKUserScript(
        source: source,
        injectionTime: .atDocumentStart,
        forMainFrameOnly: false
    )

    private static let source = """
    (() => {
      if (window.desktopAPI) return;

      const pending = new Map();
      const listeners = {};
      const makeId = () => {
        if (globalThis.crypto && typeof globalThis.crypto.randomUUID === 'function') {
          return globalThis.crypto.randomUUID();
        }
        return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
      };
      const invoke = (name, payload = {}) => new Promise((resolve, reject) => {
        const id = makeId();
        pending.set(id, {resolve, reject});
        window.webkit.messageHandlers.desktopAPI.postMessage({id, name, payload});
      });
      const on = (name, listener) => {
        (listeners[name] ||= []).push(listener);
        return () => {
          listeners[name] = (listeners[name] || []).filter((candidate) => candidate !== listener);
        };
      };

      window.__mmNativeResolve = (id, ok, value) => {
        const entry = pending.get(id);
        if (!entry) return;
        pending.delete(id);
        ok ? entry.resolve(value) : entry.reject(value);
      };
      window.__mmNativeEmit = (name, args = []) => {
        (listeners[name] || []).forEach((listener) => listener(...args));
      };

      window.desktopAPI = {
        isDev: () => Promise.resolve(false),
        getAppInfo: () => invoke("getAppInfo"),
        reactAppInitialized: () => invoke("reactAppInitialized"),
        setSessionExpired: (isExpired) => invoke("setSessionExpired", {isExpired}),
        onUserActivityUpdate: (listener) => on("userActivityUpdate", listener),
        onLogin: () => invoke("setLoggedIn", {isLoggedIn: true}),
        onLogout: () => invoke("setLoggedIn", {isLoggedIn: false}),
        invalidateSessionAttributeManifest: () => Promise.resolve(),
        resendSessionAttributes: () => Promise.resolve(),
        sendNotification: (title, body, channelId, teamId, url, silent, soundName) =>
          invoke("sendNotification", {title, body, channelId, teamId, url, silent, soundName}),
        onNotificationClicked: (listener) => on("notificationClicked", listener),
        setUnreadsAndMentions: (isUnread, mentionCount) =>
          invoke("setUnreadsAndMentions", {isUnread, mentionCount}),
        requestBrowserHistoryStatus: () => invoke("requestBrowserHistoryStatus"),
        onBrowserHistoryStatusUpdated: (listener) => on("browserHistoryStatusUpdated", listener),
        onBrowserHistoryPush: (listener) => on("browserHistoryPush", listener),
        sendBrowserHistoryPush: (path) => invoke("browserHistoryPush", {path}),
        updateTheme: (theme) => invoke("updateTheme", {theme}),
        getDarkMode: () => invoke("getDarkMode"),
        onDarkModeChanged: (listener) => on("darkModeChanged", listener),
        joinCall: (opts) => invoke("joinCall", opts),
        leaveCall: () => invoke("leaveCall"),
        callsWidgetConnected: (callID, sessionID) => invoke("callsWidgetConnected", {callID, sessionID}),
        resizeCallsWidget: (width, height) => invoke("resizeCallsWidget", {width, height}),
        sendCallsError: (err, callID, errMsg) => invoke("callsError", {err, callID, errMsg}),
        onCallsError: (listener) => on("callsError", listener),
        getDesktopSources: (opts) => invoke("getDesktopSources", opts),
        openScreenShareModal: () => invoke("openScreenShareModal"),
        onOpenScreenShareModal: (listener) => on("openScreenShareModal", listener),
        shareScreen: (sourceID, withAudio) => invoke("shareScreen", {sourceID, withAudio}),
        onScreenShared: (listener) => on("screenShared", listener),
        sendJoinCallRequest: (callID) => invoke("sendJoinCallRequest", {callID}),
        onJoinCallRequest: (listener) => on("joinCallRequest", listener),
        openLinkFromCalls: (url) => invoke("openLink", {url}),
        focusPopout: () => invoke("focusPopout"),
        openThreadForCalls: (threadID) => invoke("browserHistoryPush", {path: `/threads/${threadID}`}),
        onOpenThreadForCalls: (listener) => on("openThreadForCalls", listener),
        openStopRecordingModal: (channelID) => invoke("openStopRecordingModal", {channelID}),
        onOpenStopRecordingModal: (listener) => on("openStopRecordingModal", listener),
        openCallsUserSettings: () => invoke("openCallsUserSettings"),
        onOpenCallsUserSettings: (listener) => on("openCallsUserSettings", listener),
        onSendMetrics: (listener) => on("sendMetrics", listener),
        unregister: (channel) => { listeners[channel] = []; },
        closeWindow: () => invoke("closeWindow"),
        canPopout: () => Promise.resolve(true),
        openPopout: (path, props) => invoke("openPopout", {path, props}),
        canUsePopoutOption: () => Promise.resolve(true),
        sendToParent: (channel, ...args) => invoke("sendToParent", {channel, args}),
        onMessageFromParent: (listener) => on("messageFromParent", listener),
        sendToPopout: (id, channel, ...args) => invoke("sendToPopout", {id, channel, args}),
        onMessageFromPopout: (listener) => on("messageFromPopout", listener),
        onPopoutClosed: (listener) => on("popoutClosed", listener),
        updatePopoutTitleTemplate: (titleTemplate) => invoke("updatePopoutTitleTemplate", {titleTemplate})
      };
    })();
    """
}
