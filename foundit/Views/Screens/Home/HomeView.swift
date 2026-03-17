//
//  HomeView.swift
//  foundit
//
//  Created by Divya Panthi on 10/03/2026.
//

import SwiftUI

struct HomeView: View {
    private var viewModel = HomeViewModel()


    var body: some View {
        NavigationStack {
            VStack {
                // MARK: Header
                HomeHeaderView(userName: "Divya", userEmail: "divya.panthi03@gmail.com", hasNotification: true)
                Spacer()
            }
        }
    }
}

#Preview {
    HomeView()
}
