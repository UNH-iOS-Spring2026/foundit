//
//  NotificationView.swift
//  foundit
//

import SwiftUI

struct NotificationView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Static data
    private let notificationSections = AppNotification.groupedNotifications()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(notificationSections) { section in
                        // Section Header
                        Text(section.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 20)
                            .padding(.top, section.title == "Today" ? 0 : 24)
                            .padding(.bottom, 12)
                        
                        // Notifications in this section
                        VStack(spacing: 12) {
                            ForEach(section.notifications) { notification in
                                NotificationRowView(notification: notification)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail Image
            if let imageUrl = notification.imageUrl {
                Image(imageUrl)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                    )
            } else {
                // Default icon for notifications without images
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray4))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "bell.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
            }
            
            // Notification Content
            VStack(alignment: .leading, spacing: 6) {
                Text(notification.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(notification.message)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Text(notification.timeAgo)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    NotificationView()
}
