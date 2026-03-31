//
//  HomeView.swift
//  foundit
//
//  Created by Divya Panthi on 10/03/2026.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var searchText: String
    @State private var navigateToReport: Bool = false
    @State private var showFilterSheet: Bool = false
    @State private var selectedFilter: PostType? = nil
    @State private var postToDelete: Post? = nil
    @State private var showDeleteConfirmation = false
    @State private var postToEdit: Post? = nil
    @State private var navigateToEdit: Bool = false
    @State private var showAllItems: Bool = false

    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack {
            // MARK: Header
            HomeHeaderView(
                userName: authVM.currentUser?.displayName ?? "User",
                userEmail: authVM.currentUser?.email ?? "",
                hasNotification: true,
                onPost: {
                    navigateToReport = true
                })
            // MARK: Search + Filter
            HStack(spacing: 10){
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search items…", text: $viewModel.searchText)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
                .padding(.horizontal, 12)
                
                
                Button {
                    showFilterSheet = true
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
                    showAllItems = true
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
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Error loading posts")
                            .font(.system(size: 16, weight: .semibold))
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await viewModel.loadItems()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 32)
                } else if viewModel.filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No items found")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Try adjusting your search")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.filteredItems) { item in
                            NavigationLink {
                                PostDetailView(item: item)
                            } label: {
                                ItemCardView(
                                    item: item,
                                    onDelete: {
                                        postToDelete = item
                                        showDeleteConfirmation = true
                                    },
                                    onEdit: {
                                        postToEdit = item
                                        navigateToEdit = true
                                    },
                                    canDelete: item.createdBy == AppConfig.placeholderUserId,
                                    canEdit: item.createdBy == AppConfig.placeholderUserId
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
            .refreshable {
                await viewModel.refreshItems()
            }
            Spacer()
        }
        .navigationDestination(isPresented: $navigateToReport) {
            PostItemView()
                .environmentObject(postViewModel)
        }
        .navigationDestination(isPresented: $navigateToEdit) {
            if let post = postToEdit {
                PostItemView(postToEdit: post)
                    .environmentObject(postViewModel)
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView(selectedFilter: $selectedFilter) {
                Task {
                    if let filter = selectedFilter {
                        await viewModel.loadItems(ofType: filter)
                    } else {
                        await viewModel.loadItems()
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showAllItems) {
            AllItemsView()
                .environmentObject(postViewModel)
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
        }
        .onChange(of: navigateToReport) { oldValue, newValue in
            // When returning from PostItemView (navigateToReport changes from true to false)
            if oldValue == true && newValue == false {
                Task {
                    await viewModel.refreshItems()
                }
            }
        }
        .onChange(of: navigateToEdit) { oldValue, newValue in
            // When returning from edit view, refresh items
            if oldValue == true && newValue == false {
                Task {
                    await viewModel.refreshItems()
                }
                postToEdit = nil
            }
        }
        .alert("Delete Post", isPresented: $showDeleteConfirmation, presenting: postToDelete) { post in
            Button("Cancel", role: .cancel) {
                postToDelete = nil
            }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deletePost(post)
                    postToDelete = nil
                }
            }
        } message: { post in
            Text("Are you sure you want to delete '\(post.title)'? This action cannot be undone.")
        }
    }
}

// MARK: - Filter Sheet View
struct FilterSheetView: View {
    @Binding var selectedFilter: PostType?
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Filter Items")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.top, 20)
                
                VStack(spacing: 12) {
                    FilterOptionRow(
                        title: "All Items",
                        isSelected: selectedFilter == nil
                    ) {
                        selectedFilter = nil
                    }
                    
                    FilterOptionRow(
                        title: "Lost Items",
                        isSelected: selectedFilter == .lost
                    ) {
                        selectedFilter = .lost
                    }
                    
                    FilterOptionRow(
                        title: "Found Items",
                        isSelected: selectedFilter == .found
                    ) {
                        selectedFilter = .found
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    onApply()
                    dismiss()
                } label: {
                    Text("Apply Filter")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.55, green: 0.60, blue: 0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
// MARK: - Filter Option Row
struct FilterOptionRow: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.55, green: 0.60, blue: 0.85))
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}


