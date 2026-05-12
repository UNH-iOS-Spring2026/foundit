//
//  LocalNotificationManager.swift
//  foundit
//

import Foundation
import UserNotifications
import UIKit

final class LocalNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotificationManager()
    static let enabledPreferenceKey = "localNotificationsEnabled"

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledPreferenceKey) as? Bool ?? true
    }

    private override init() {
        super.init()
    }

    // Call once at app launch to register as delegate and request permission
    func setup() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error = error {
                print("LocalNotificationManager: permission error: \(error.localizedDescription)")
            }
        }
    }

    // Post a banner for the given AppNotification
    func deliver(from notification: AppNotification) {
        guard isEnabled else {
            print("[LocalNotificationManager] suppressed — notifications disabled by user")
            return
        }
        print("[LocalNotificationManager] deliver called — title: '\(notification.title)'")
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = .default

        var userInfo: [String: Any] = ["type": notification.type.rawValue]
        if let postId = notification.relatedPostId {
            userInfo["relatedPostId"] = postId
        }
        content.userInfo = userInfo

        let identifier = notification.id ?? UUID().uuidString
        // Minimal delay — triggers immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("LocalNotificationManager: failed to deliver: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Badge Management

    func setBadge(count: Int) {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count) { error in
                if let error { print("[LocalNotificationManager] setBadgeCount error: \(error)") }
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner, play sound, and update badge even when app is foregrounded
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("[LocalNotificationManager] user tapped notification userInfo=\(userInfo)")

        if let postId = userInfo["relatedPostId"] as? String, !postId.isEmpty {
            NotificationCenter.default.post(
                name: .notificationBannerTapped,
                object: nil,
                userInfo: ["relatedPostId": postId]
            )
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let notificationBannerTapped = Notification.Name("notificationBannerTapped")
}
