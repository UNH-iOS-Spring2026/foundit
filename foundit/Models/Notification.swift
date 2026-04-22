//
//  Notification.swift
//  foundit


import Foundation
import FirebaseFirestore

// MARK: - Notification Type
enum NotificationType: String, Codable {
    case similarPost = "similar_post"
    case message = "message"
    case match = "match"
    case statusUpdate = "status_update"
}

// MARK: - Notification Model
struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var type: NotificationType
    var title: String
    var message: String
    var relatedPostId: String?  // ID of the related post
    var relatedUserId: String?  // ID of the user who triggered the notification
    var imageUrl: String?
    var recipientId: String  // User who receives this notification
    var timestamp: Timestamp
    var isRead: Bool
    
    // Custom decoder to handle missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        type = try container.decode(NotificationType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        relatedPostId = try container.decodeIfPresent(String.self, forKey: .relatedPostId)
        relatedUserId = try container.decodeIfPresent(String.self, forKey: .relatedUserId)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        recipientId = try container.decode(String.self, forKey: .recipientId)
        timestamp = try container.decode(Timestamp.self, forKey: .timestamp)
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
    }
    
    init(
        id: String? = nil,
        type: NotificationType,
        title: String,
        message: String,
        relatedPostId: String? = nil,
        relatedUserId: String? = nil,
        imageUrl: String? = nil,
        recipientId: String,
        timestamp: Timestamp = Timestamp(),
        isRead: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.relatedPostId = relatedPostId
        self.relatedUserId = relatedUserId
        self.imageUrl = imageUrl
        self.recipientId = recipientId
        self.timestamp = timestamp
        self.isRead = isRead
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case message
        case relatedPostId
        case relatedUserId
        case imageUrl
        case recipientId
        case timestamp
        case isRead
    }
}

// MARK: - Grouped Notifications
struct NotificationSection: Identifiable {
    let id = UUID()
    let title: String
    let notifications: [AppNotification]
}

// MARK: - Helper Extensions
extension AppNotification {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp.dateValue())
    }
    
    // Helper to group notifications by date
    static func groupNotifications(_ notifications: [AppNotification]) -> [NotificationSection] {
        let calendar = Calendar.current
        let now = Date()
        
        var grouped: [String: [AppNotification]] = [:]
        
        for notification in notifications {
            let notificationDate = notification.timestamp.dateValue()
            let sectionTitle: String
            
            if calendar.isDateInToday(notificationDate) {
                sectionTitle = "Today"
            } else if calendar.isDateInYesterday(notificationDate) {
                sectionTitle = "Yesterday"
            } else if isThisWeek(date: notificationDate, relativeTo: now, calendar: calendar) {
                sectionTitle = "This Week"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d"
                sectionTitle = formatter.string(from: notificationDate)
            }
            
            grouped[sectionTitle, default: []].append(notification)
        }
        
        // Sort sections by priority
        let sortedKeys = grouped.keys.sorted { key1, key2 in
            let priority1: Int
            let priority2: Int
            
            switch key1 {
            case "Today": priority1 = 0
            case "Yesterday": priority1 = 1
            case "This Week": priority1 = 2
            default: priority1 = 3
            }
            
            switch key2 {
            case "Today": priority2 = 0
            case "Yesterday": priority2 = 1
            case "This Week": priority2 = 2
            default: priority2 = 3
            }
            
            return priority1 < priority2
        }
        
        return sortedKeys.map { key in
            NotificationSection(title: key, notifications: grouped[key] ?? [])
        }
    }
    
    // Helper to check if date is in current week
    private static func isThisWeek(date: Date, relativeTo now: Date, calendar: Calendar) -> Bool {
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return false
        }
        
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return false
        }
        
        let isInWeek = date >= weekStart && date < weekEnd
        let isToday = calendar.isDateInToday(date)
        let isYesterday = calendar.isDateInYesterday(date)
        
        return isInWeek && !isToday && !isYesterday
    }
}
