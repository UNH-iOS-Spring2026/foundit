//
//  NotificationView.swift
//  foundit
//

import SwiftUI

struct NotificationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NotificationViewModel()
    @StateObject private var postViewModel = PostViewModel()
    @State private var selectedPost: Post? = nil
    @State private var showingErrorAlert = false
    @State private var errorAlertMessage = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading notifications...")
                } else if viewModel.notifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.notifications.isEmpty {
                        Menu {
                            Button {
                                Task {
                                    await viewModel.markAllAsRead()
                                }
                            } label: {
                                Label("Mark All as Read", systemImage: "checkmark.circle")
                            }
                            .disabled(viewModel.unreadCount == 0)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18))
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(item: post)
            }
            .alert("Post Not Available", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorAlertMessage)
            }
            .task {
                await viewModel.fetchNotifications()
            }
            .refreshable {
                await viewModel.fetchNotifications()
            }
        }
    }
    
    // MARK: - Notifications List
    private var notificationsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.notificationSections) { section in
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
                            NotificationRowView(
                                notification: notification,
                                onTap: {
                                    Task {
                                        await viewModel.markAsRead(notification)
                                        // Navigate to the related post if available
                                        if let postId = notification.relatedPostId {
                                            await fetchAndNavigateToPost(postId: postId)
                                        }
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteNotification(notification)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Notifications")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text("When someone posts a similar item to yours, you'll see it here.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Helper Functions
    private func fetchAndNavigateToPost(postId: String) async {
        do {
            if let post = try await postViewModel.fetchPostById(id: postId) {
                selectedPost = post
            } else {
                errorAlertMessage = "This post is no longer available. It may have been deleted or removed."
                showingErrorAlert = true
            }
        } catch {
            errorAlertMessage = "Unable to load this post. Please try again later."
            showingErrorAlert = true
        }
    }
}

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: AppNotification
    var onTap: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail Image
                if let imageUrl = notification.imageUrl {
                    // Try to load from Firebase Storage URL or local asset
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure(_):
                            // Fallback to local asset if URL fails
                            Image(imageUrl)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .empty:
                            ProgressView()
                                .frame(width: 70, height: 70)
                        @unknown default:
                            defaultIconView
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                    )
                } else {
                    defaultIconView
                }
                
                // Notification Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        // Unread indicator
                        if !notification.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.message)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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
            .background(notification.isRead ? Color(.systemBackground) : Color(.systemBackground).opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(notification.isRead ? Color.clear : Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if let onTap, !notification.isRead {
                Button {
                    onTap()
                } label: {
                    Label("Mark as Read", systemImage: "checkmark")
                }
            }
        }
    }
    
    private var defaultIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray4))
                .frame(width: 70, height: 70)
            
            Image(systemName: iconForNotificationType)
                .font(.system(size: 28))
                .foregroundStyle(.white)
        }
    }
    
    private var iconForNotificationType: String {
        switch notification.type {
        case .similarPost:
            return "magnifyingglass.circle.fill"
        case .message:
            return "message.fill"
        case .match:
            return "checkmark.circle.fill"
        case .statusUpdate:
            return "bell.fill"
        }
    }
}

// MARK: - Preview
#Preview {
    NotificationView()
}
