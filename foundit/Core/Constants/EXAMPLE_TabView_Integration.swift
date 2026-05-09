//
//  EXAMPLE_TabView_With_Notification_Badge.swift
//  foundit
//
//  This is an EXAMPLE showing how to integrate notification badges into your tab bar.
//  Adapt this to your actual TabView implementation.
//

import SwiftUI

// EXAMPLE: This shows how to add notification badge to your tab view
struct ExampleMainTabView: View {
    @StateObject private var notificationViewModel = NotificationViewModel()
    @State private var searchText: String = ""
    
    var body: some View {
        TabView {
            // Home Tab
            HomeView(searchText: $searchText)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            // Notifications Tab with Badge
            NotificationView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
                .badge(notificationViewModel.unreadCount > 0 ? notificationViewModel.unreadCount : 0) // Only show badge when there are unread notifications
            
            // Other tabs...
        }
        .task {
            // Fetch notifications and update badge when view appears
            await notificationViewModel.fetchNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh unread count when app comes to foreground
            Task {
                await notificationViewModel.refreshUnreadCount()
            }
        }
    }
}

// MARK: - Alternative: Using EnvironmentObject for Shared State
// This approach allows multiple views to share the same notification state

// EXAMPLE: If this were your actual App struct, you would add @main
// For demonstration purposes only - remove @main since your app already has an entry point
struct ExampleFoundItApp: App {
    @StateObject private var notificationViewModel = NotificationViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabViewWithEnvironment()
                .environmentObject(notificationViewModel)
        }
    }
}

struct MainTabViewWithEnvironment: View {
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @State private var searchText: String = ""
    
    var body: some View {
        TabView {
            HomeView(searchText: $searchText)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            NotificationView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
                .badge(notificationViewModel.unreadCount)
            
            // Other tabs...
        }
        .task {
            await notificationViewModel.fetchNotifications()
        }
    }
}

// MARK: - Periodic Refresh Example
// This example shows how to periodically check for new notifications

struct TabViewWithPeriodicRefresh: View {
    @StateObject private var notificationViewModel = NotificationViewModel()
    @State private var refreshTimer: Timer?
    
    var body: some View {
        TabView {
            NotificationView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
                .badge(notificationViewModel.unreadCount)
        }
        .onAppear {
            // Start periodic refresh (every 60 seconds)
            startPeriodicRefresh()
        }
        .onDisappear {
            // Stop refresh when view disappears
            stopPeriodicRefresh()
        }
    }
    
    private func startPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task {
                await notificationViewModel.refreshUnreadCount()
            }
        }
    }
    
    private func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Custom Notification Bell Icon with Badge
// If you want a custom bell icon with visual badge

struct NotificationBellButton: View {
    let unreadCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.primary)
                
                if unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                        
                        Text("\(min(unreadCount, 99))") // Cap at 99
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 8, y: -8)
                }
            }
        }
    }
}

// Usage in Navigation Bar:
struct HomeViewWithNotificationBell: View {
    @StateObject private var notificationViewModel = NotificationViewModel()
    @State private var showNotifications = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Home Content")
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NotificationBellButton(unreadCount: notificationViewModel.unreadCount) {
                        showNotifications = true
                    }
                }
            }
            .sheet(isPresented: $showNotifications) {
                NotificationView()
            }
            .task {
                await notificationViewModel.refreshUnreadCount()
            }
        }
    }
}

#Preview {
    ExampleMainTabView()
}
