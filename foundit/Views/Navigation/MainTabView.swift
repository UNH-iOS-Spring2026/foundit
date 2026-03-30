//
//  MainTabView.swift
//  foundit
//
//  Created by Aryan Tandon on 3/10/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, report, chat, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView(searchText: .constant(""))
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(Tab.home)

            // Report Tab
            ReportPlaceholderView()
                .tabItem {
                    Image(systemName: "plus.app")
                    Text("Report")
                }
                .tag(Tab.report)

            // Chat Tab
            ChatPlaceholderView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
                .tag(Tab.chat)

            // Profile Tab
            ProfilePlaceholderView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(Tab.profile)
        }
    }
}

// Placeholder Views, we will replace these as we biuld views.

struct HomePlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Home Screen")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
        }
    }
}

struct ReportPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Report Screen")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Report")
        }
    }
}

struct ChatPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Chat Screen")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Inbox")
        }
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Profile Screen")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    MainTabView()
        
}
