//
//  NotificationViewModel.swift
//  foundit
//

import Foundation
import Combine

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var notificationSections: [NotificationSection] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let notificationService = NotificationService()
    private let currentUserId: String
    
    init(userId: String = AppConfig.currentUserId) {
        self.currentUserId = userId
    }
    
    // MARK: - Fetch Notifications
    func fetchNotifications() async {
        guard !currentUserId.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            notifications = try await notificationService.fetchNotifications(for: currentUserId)
            notificationSections = AppNotification.groupNotifications(notifications)
            
            // Update unread count
            unreadCount = notifications.filter { !$0.isRead }.count
            
        } catch {
            errorMessage = "Failed to load notifications: \(error.localizedDescription)"
            print("Error fetching notifications: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Mark as Read
    func markAsRead(_ notification: AppNotification) async {
        guard let notificationId = notification.id, !notification.isRead else { return }
        
        do {
            try await notificationService.markAsRead(notificationId: notificationId)
            
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                notifications[index].isRead = true
                unreadCount = max(0, unreadCount - 1)
            }
            
            // Refresh sections
            notificationSections = AppNotification.groupNotifications(notifications)
            
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }
    
    // MARK: - Mark All as Read
    func markAllAsRead() async {
        guard !currentUserId.isEmpty else { return }
        
        do {
            try await notificationService.markAllAsRead(for: currentUserId)
            
            // Update local state
            for index in notifications.indices {
                notifications[index].isRead = true
            }
            unreadCount = 0
            
            // Refresh sections
            notificationSections = AppNotification.groupNotifications(notifications)
            
        } catch {
            errorMessage = "Failed to mark all as read: \(error.localizedDescription)"
            print("Error marking all as read: \(error)")
        }
    }
    
    // MARK: - Delete Notification
    func deleteNotification(_ notification: AppNotification) async {
        guard let notificationId = notification.id else { return }
        
        do {
            try await notificationService.deleteNotification(id: notificationId)
            
            // Update local state
            notifications.removeAll { $0.id == notificationId }
            if !notification.isRead {
                unreadCount = max(0, unreadCount - 1)
            }
            
            // Refresh sections
            notificationSections = AppNotification.groupNotifications(notifications)
            
        } catch {
            errorMessage = "Failed to delete notification: \(error.localizedDescription)"
            print("Error deleting notification: \(error)")
        }
    }
    
    // MARK: - Refresh Unread Count
    func refreshUnreadCount() async {
        guard !currentUserId.isEmpty else { return }
        
        do {
            unreadCount = try await notificationService.getUnreadCount(for: currentUserId)
        } catch {
            print("Error refreshing unread count: \(error)")
        }
    }
}
