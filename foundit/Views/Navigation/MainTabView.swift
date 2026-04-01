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
    @StateObject private var tabRouter = TabRouter()
    @State private var searchText: String = ""

    var body: some View {
        TabView(selection: $tabRouter.selectedTab) {
            NavigationStack {
                HomeView(searchText: $searchText)
            }
            .tag(AppTab.home)
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }

            NavigationStack {
                ReportScreen()
            }
            .tag(AppTab.report)
            .tabItem {
                Image(systemName: "plus")
                Text("Report")
            }

            NavigationStack {
                MessageScreen()
            }
            .tag(AppTab.chat)
            .tabItem {
                Image(systemName: "message")
                Text("Chat")
            }

            NavigationStack {
                ProfileScreen()
            }
            .tag(AppTab.profile)
            .tabItem {
                Image(systemName: "person")
                Text("Profile")
            }
        }
        .environmentObject(postViewModel)
        .environmentObject(chatViewModel)
        .environmentObject(tabRouter)
    }
}

#Preview {
    MainTabView()
        
}
