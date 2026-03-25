//
//  MainTabView.swift
//  foundit
//
//  Created by Aryan Tandon on 3/24/26.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var postViewModel = PostViewModel()
    @StateObject private var chatViewModel = ChatViewModel()

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }

            ReportScreen()
                .tabItem {
                    Image(systemName: "plus")
                    Text("Report")
                }

            MessageScreen()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }

            ProfileScreen()
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
