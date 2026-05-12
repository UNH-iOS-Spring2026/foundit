//
//  NotificationViewModel.swift
//  foundit
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var notificationSections: [NotificationSection] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let notificationService = NotificationService()
    private let currentUserId: String
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    // Records the moment the listener was registered; only docs timestamped after this get a banner
    private var listenerStartTime: Date = .distantFuture

    init(userId: String = AppConfig.currentUserId) {
        self.currentUserId = userId
        print("[NotificationViewModel] init — userId: '\(userId)'")
        startListening()
        Task { await fetchNotifications() }
    }

    deinit {
        listenerRegistration?.remove()
    }

    // MARK: - Fetch Notifications
    func fetchNotifications() async {
        guard !currentUserId.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            notifications = try await notificationService.fetchNotifications(for: currentUserId)
            notificationSections = AppNotification.groupNotifications(notifications)
            unreadCount = notifications.filter { !$0.isRead }.count
        } catch {
            errorMessage = "Failed to load notifications: \(error.localizedDescription)"
            print("[NotificationViewModel] fetchNotifications error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Mark as Read
    func markAsRead(_ notification: AppNotification) async {
        guard let notificationId = notification.id, !notification.isRead else { return }

        do {
            try await notificationService.markAsRead(notificationId: notificationId)

            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                notifications[index].isRead = true
                unreadCount = max(0, unreadCount - 1)
            }
            notificationSections = AppNotification.groupNotifications(notifications)
        } catch {
            print("[NotificationViewModel] markAsRead error: \(error)")
        }
    }

    // MARK: - Mark All as Read
    func markAllAsRead() async {
        guard !currentUserId.isEmpty else { return }

        do {
            try await notificationService.markAllAsRead(for: currentUserId)

            for index in notifications.indices {
                notifications[index].isRead = true
            }
            unreadCount = 0
            notificationSections = AppNotification.groupNotifications(notifications)
        } catch {
            errorMessage = "Failed to mark all as read: \(error.localizedDescription)"
            print("[NotificationViewModel] markAllAsRead error: \(error)")
        }
    }

    // MARK: - Delete Notification
    func deleteNotification(_ notification: AppNotification) async {
        guard let notificationId = notification.id else { return }

        do {
            try await notificationService.deleteNotification(id: notificationId)

            notifications.removeAll { $0.id == notificationId }
            if !notification.isRead {
                unreadCount = max(0, unreadCount - 1)
            }
            notificationSections = AppNotification.groupNotifications(notifications)
        } catch {
            errorMessage = "Failed to delete notification: \(error.localizedDescription)"
            print("[NotificationViewModel] deleteNotification error: \(error)")
        }
    }

    // MARK: - Refresh Unread Count
    func refreshUnreadCount() async {
        guard !currentUserId.isEmpty else { return }

        do {
            unreadCount = try await notificationService.getUnreadCount(for: currentUserId)
        } catch {
            print("[NotificationViewModel] refreshUnreadCount error: \(error)")
        }
    }

    // MARK: - Real-time Listener
    private func startListening() {
        guard !currentUserId.isEmpty else {
            print("[NotificationViewModel] startListening SKIPPED — userId is empty")
            return
        }

        listenerStartTime = Date()
        print("[NotificationViewModel] startListening — userId: '\(currentUserId)', startTime: \(listenerStartTime)")

        listenerRegistration = db.collection("notifications")
            .whereField("recipientId", isEqualTo: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("[NotificationViewModel] listener error: \(error)")
                    return
                }

                guard let snapshot = snapshot else { return }

                print("[NotificationViewModel] snapshot received — \(snapshot.documentChanges.count) change(s)")

                for change in snapshot.documentChanges {
                    print("[NotificationViewModel]   change type: \(change.type.rawValue), docId: \(change.document.documentID)")

                    guard change.type == .added else { continue }

                    var notification: AppNotification
                    do {
                        notification = try change.document.data(as: AppNotification.self)
                    } catch {
                        print("[NotificationViewModel]   failed to decode doc \(change.document.documentID): \(error)")
                        print("[NotificationViewModel]   raw data: \(change.document.data())")
                        continue
                    }

                    if notification.id == nil || notification.id?.isEmpty == true {
                        notification.id = change.document.documentID
                    }

                    let docTime = notification.timestamp.dateValue()
                    let isNew = docTime > self.listenerStartTime
                    print("[NotificationViewModel]   doc timestamp: \(docTime), listenerStart: \(self.listenerStartTime), isNew: \(isNew)")

                    guard isNew else {
                        print("[NotificationViewModel]   skipping — pre-existing doc")
                        continue
                    }

                    // Always update in-app state so the badge and list stay current
                    // regardless of whether the OS banner toggle is on or off
                    if !self.notifications.contains(where: { $0.id == notification.id }) {
                        self.notifications.insert(notification, at: 0)
                        if !notification.isRead {
                            self.unreadCount += 1
                        }
                        self.notificationSections = AppNotification.groupNotifications(self.notifications)
                    }

                    // Fire the OS banner only if the user has it enabled
                    print("[NotificationViewModel]   delivering banner for: '\(notification.title)'")
                    LocalNotificationManager.shared.deliver(from: notification)
                }
            }
    }
}
