//
//  Notification.swift
//  foundit


import Foundation

// MARK: - Notification Model
struct AppNotification: Identifiable {
    let id: String
    let title: String
    let message: String
    let imageUrl: String?
    let timestamp: Date
    let isRead: Bool
    
    init(
        id: String = UUID().uuidString,
        title: String,
        message: String,
        imageUrl: String? = nil,
        timestamp: Date,
        isRead: Bool = false
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.imageUrl = imageUrl
        self.timestamp = timestamp
        self.isRead = isRead
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
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Static Mock Data
extension AppNotification {
    static var mockNotifications: [AppNotification] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            // Today
            AppNotification(
                title: "Item Found Near You",
                message: "Someone found wireless earbuds matching your lost item description near Maxcy Hall. Check it out now!",
                imageUrl: "earphones",
                timestamp: calendar.date(byAdding: .hour, value: -2, to: now) ?? now
            ),
            AppNotification(
                title: "New Message",
                message: "You have a new message from John about your lost charger. They might have additional information.",
                imageUrl: "charger",
                timestamp: calendar.date(byAdding: .hour, value: -5, to: now) ?? now
            ),
            
            // Yesterday
            AppNotification(
                title: "Potential Match",
                message: "We found a potential match for your lost keys near the Campus Library. The description matches closely.",
                imageUrl: "keys",
                timestamp: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),
            AppNotification(
                title: "Item Claimed Successfully",
                message: "Your found item 'Black Backpack' has been successfully claimed by the rightful owner. Great job!",
                imageUrl: "backpack",
                timestamp: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),
            AppNotification(
                title: "Update Required",
                message: "Don't forget to update the status of your lost laptop case. Is it still missing?",
                imageUrl: "laptop",
                timestamp: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),
            
            // This Week (3-6 days ago)
            AppNotification(
                title: "Someone Commented",
                message: "Sarah commented on your found phone post. They mentioned it looks familiar and want to verify ownership.",
                imageUrl: "phone",
                timestamp: calendar.date(byAdding: .day, value: -3, to: now) ?? now
            ),
            AppNotification(
                title: "Similar Item Reported",
                message: "A similar pair of glasses was reported found near your last seen location in Bethel Hall.",
                imageUrl: "glasses",
                timestamp: calendar.date(byAdding: .day, value: -4, to: now) ?? now
            ),
            AppNotification(
                title: "Weekly Activity Summary",
                message: "You have 3 active posts and 2 new potential matches this week. Keep checking for updates!",
                imageUrl: nil,
                timestamp: calendar.date(byAdding: .day, value: -5, to: now) ?? now
            )
        ]
    }
    
    static func groupedNotifications() -> [NotificationSection] {
        let calendar = Calendar.current
        let now = Date()
        let notifications = mockNotifications
        
        var grouped: [String: [AppNotification]] = [:]
        
        for notification in notifications {
            let sectionTitle: String
            
            if calendar.isDateInToday(notification.timestamp) {
                sectionTitle = "Today"
            } else if calendar.isDateInYesterday(notification.timestamp) {
                sectionTitle = "Yesterday"
            } else if isThisWeek(date: notification.timestamp, relativeTo: now, calendar: calendar) {
                sectionTitle = "This Week"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d"
                sectionTitle = formatter.string(from: notification.timestamp)
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
        // Get the start of this week (Sunday or Monday depending on locale)
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return false
        }
        
        // Get the end of this week
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return false
        }
        
        // Check if date falls within this week (excluding today and yesterday which have their own sections)
        let isInWeek = date >= weekStart && date < weekEnd
        let isToday = calendar.isDateInToday(date)
        let isYesterday = calendar.isDateInYesterday(date)
        
        return isInWeek && !isToday && !isYesterday
    }
}
