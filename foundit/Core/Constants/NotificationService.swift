//
//  NotificationService.swift
//  foundit
//

import Foundation
import FirebaseFirestore

class NotificationService {
    private let db = Firestore.firestore()
    private let notificationsCollection = "notifications"
    
    // MARK: - Create Notification
    func createNotification(_ notification: AppNotification) async throws {
        try db.collection(notificationsCollection).addDocument(from: notification)
    }
    
    // MARK: - Fetch Notifications for User
    func fetchNotifications(for userId: String) async throws -> [AppNotification] {
        let snapshot = try await db.collection(notificationsCollection)
            .whereField("recipientId", isEqualTo: userId)
            .getDocuments()
        
        var notifications: [AppNotification] = []
        for document in snapshot.documents {
            do {
                var notification = try document.data(as: AppNotification.self)
                if notification.id == nil || notification.id?.isEmpty == true {
                    notification.id = document.documentID
                }
                notifications.append(notification)
            } catch {
                print("Failed to decode notification: \(error)")
                continue
            }
        }
        
        // Sort by timestamp, newest first
        notifications.sort { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
        return notifications
    }
    
    // MARK: - Mark as Read
    func markAsRead(notificationId: String) async throws {
        try await db.collection(notificationsCollection)
            .document(notificationId)
            .updateData(["isRead": true])
    }
    
    // MARK: - Mark All as Read
    func markAllAsRead(for userId: String) async throws {
        let snapshot = try await db.collection(notificationsCollection)
            .whereField("recipientId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        let batch = db.batch()
        for document in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: document.reference)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Delete Notification
    func deleteNotification(id: String) async throws {
        try await db.collection(notificationsCollection).document(id).delete()
    }
    
    // MARK: - Get Unread Count
    func getUnreadCount(for userId: String) async throws -> Int {
        let snapshot = try await db.collection(notificationsCollection)
            .whereField("recipientId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        return snapshot.documents.count
    }
    
    // MARK: - Create Similar Post Notification
    /// Creates notifications for users who have posted items that match the new post
    func notifyUsersOfSimilarPost(newPost: Post, similarPosts: [Post]) async {
        for similarPost in similarPosts {
            // Don't notify the user about their own post
            guard similarPost.createdBy != newPost.createdBy else { continue }
            
            // Only notify if the types are opposite (lost vs found)
            guard newPost.type != similarPost.type else { continue }
            
            let notification = AppNotification(
                type: .similarPost,
                title: "Similar Item \(newPost.type == .found ? "Found" : "Lost")!",
                message: "Someone \(newPost.type == .found ? "found" : "lost") a \(newPost.category) near \(newPost.lastSeenLocationText). It might match your \(similarPost.type == .lost ? "lost" : "found") item '\(similarPost.title)'.",
                relatedPostId: newPost.id,
                relatedUserId: newPost.createdBy,
                imageUrl: newPost.primaryImageUrl,
                recipientId: similarPost.createdBy,
                timestamp: Timestamp()
            )
            
            do {
                try await createNotification(notification)
            } catch {
                print("Failed to create notification: \(error)")
            }
        }
    }
}
