//
//  HomeView.swift
//  foundit
//
//  Created by Divya Panthi on 10/03/2026.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Binding var searchText: String
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
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
                
                HStack {
                    Spacer()
                    Button("See all") {
                        // TODO: navigate to full list
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(red: 0.55, green: 0.60, blue: 0.85))
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                
                // Grid
                ScrollView {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.filteredItems) { item in
                                NavigationLink {
                                    Text(item.title)
                                } label: {
                                    ItemCardView(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
                Spacer()
            }
        }
    }
}
