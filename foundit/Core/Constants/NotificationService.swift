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
    /// Creates notifications for users whose posts match by category, opposite type, AND are within 5 km.
    func notifyUsersOfSimilarPost(newPost: Post, similarPosts: [Post]) async {
        var notifiedUserIds = Set<String>()

        for similarPost in similarPosts {
            // Don't notify the user about their own post
            guard similarPost.createdBy != newPost.createdBy else { continue }

            // Only notify if the types are opposite (lost vs found)
            guard newPost.type != similarPost.type else { continue }

            // Only notify if both posts are within 5 km of each other
            let km = distanceInKm(from: newPost.lastSeenLocation, to: similarPost.lastSeenLocation)
            guard km <= 5.0 else { continue }

            // Send at most one notification per recipient
            guard !notifiedUserIds.contains(similarPost.createdBy) else { continue }
            notifiedUserIds.insert(similarPost.createdBy)

            let distanceText = km < 1.0
                ? "\(Int(km * 1000)) m"
                : String(format: "%.1f km", km)

            let notification = AppNotification(
                type: .similarPost,
                title: "Possible Match Nearby!",
                message: "Someone \(newPost.type == .found ? "found" : "lost") a \(newPost.category) at \(newPost.lastSeenLocationText) — only \(distanceText) from where you \(similarPost.type == .lost ? "lost" : "found") '\(similarPost.title)'.",
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

    // MARK: - Haversine Distance
    /// Returns the great-circle distance in kilometres between two GeoPoints.
    private func distanceInKm(from: GeoPoint, to: GeoPoint) -> Double {
        let r = 6371.0
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
