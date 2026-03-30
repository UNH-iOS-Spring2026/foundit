//
//  MainTabView.swift
//  foundit
//
//  Created by Divya Panthi on 26/03/2026.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var postViewModel = PostViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var searchText: String = ""

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(searchText: $searchText)
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }

            NavigationStack {
                ReportScreen()
            }
            .tabItem {
                Image(systemName: "plus")
                Text("Report")
            }

            NavigationStack {
                MessageScreen()
            }
            .tabItem {
                Image(systemName: "message")
                Text("Chat")
            }

            NavigationStack {
                ProfileScreen()
            }
            .tabItem {
                Image(systemName: "person")
                Text("Profile")
            }
        }
        .environmentObject(postViewModel)
        .environmentObject(chatViewModel)
    }
}

#Preview {
    MainTabView()
        
}
