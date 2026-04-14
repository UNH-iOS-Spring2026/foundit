//
//  PoliceTabView.swift
//  foundit
//

import SwiftUI

struct PoliceTabView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var postViewModel = PostViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                Text("Police Dashboard")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .tabItem {
                Image(systemName: "shield")
                Text("Dashboard")
            }

            NavigationStack {
                MessageScreen()
            }
            .tabItem {
                Image(systemName: "message")
                Text("Inbox")
            }

            NavigationStack {
                ProfileScreen()
            }
            .tabItem {
                Image(systemName: "person")
                Text("Profile")
            }
        }
        .environmentObject(chatViewModel)
        .environmentObject(postViewModel)
    }
}

#Preview {
    PoliceTabView()
}
