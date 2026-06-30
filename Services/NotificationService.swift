// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    @MainActor var onNotificationURL: ((URL) -> Void)?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            // The send path returns a failure if notifications remain unavailable.
        }
    }

    func send(_ payload: Any?) async -> [String: Any] {
        guard let payload = payload as? [String: Any] else {
            return ["status": "error", "reason": "invalid_payload"]
        }

        let content = UNMutableNotificationContent()
        content.title = payload["title"] as? String ?? "Mattermost"
        content.body = payload["body"] as? String ?? ""
        content.sound = (payload["silent"] as? Bool == true) ? nil : .default
        content.userInfo = [
            "channelId": payload["channelId"] as? String ?? "",
            "teamId": payload["teamId"] as? String ?? "",
            "url": payload["url"] as? String ?? "",
        ]

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await UNUserNotificationCenter.current().add(request)
            return ["status": "success"]
        } catch {
            return ["status": "error", "reason": error.localizedDescription]
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let rawURL = response.notification.request.content.userInfo["url"] as? String,
           let url = URL(string: rawURL) {
            Task { @MainActor in
                onNotificationURL?(url)
            }
        }
        completionHandler()
    }
}
