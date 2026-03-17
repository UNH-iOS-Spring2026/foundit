//
//  HomeView.swift
//  foundit
//
//  Created by Divya Panthi on 10/03/2026.
//

import SwiftUI

struct HomeView: View {
//    private var viewModel = HomeViewModel()
    @Binding var searchText: String
    
    var body: some View {
        NavigationStack {
            VStack {
                // MARK: Header
                HomeHeaderView(
                    userName: "Divya",
                    userEmail: "divya.panthi03@gmail.com",
                    hasNotification: true,
                    onPost: {//Navigate to Add Post Screen
                    })
                // MARK: Search + Filter
                HStack(spacing: 10){
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search items…", text: $searchText)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                    .padding(.horizontal, 12)

                    
                    Button {
                          // TODO: show filter sheet
                      } label: {
                          Image(.filter)
                              .font(.system(size: 1))
                              .foregroundStyle(Color(red: 0.55, green: 0.60, blue: 0.85))
                      }
                      .padding(.trailing)
                }
            }
            Spacer()
        }
    }
}

#Preview {
    HomeView(searchText: .constant(""))
}
