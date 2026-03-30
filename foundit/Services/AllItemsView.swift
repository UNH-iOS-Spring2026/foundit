//
//  AllItemsView.swift
//  foundit
//

import SwiftUI

struct AllItemsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var postViewModel: PostViewModel
    @StateObject private var viewModel = HomeViewModel()
    
    @State private var selectedFilter: PostType? = nil
    @State private var searchText: String = ""
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var filteredItems: [Post] {
        var items = viewModel.filteredItems
        
        // Apply type filter if selected
        if let filter = selectedFilter {
            items = items.filter { $0.type == filter }
        }
        
        return items
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 10) {
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
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedFilter == nil
                        ) {
                            selectedFilter = nil
                        }
                        
                        FilterChip(
                            title: "Lost",
                            isSelected: selectedFilter == .lost
                        ) {
                            selectedFilter = .lost
                        }
                        
                        FilterChip(
                            title: "Found",
                            isSelected: selectedFilter == .found
                        ) {
                            selectedFilter = .found
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 12)
                
                Divider()
                
                // Items Grid
                ScrollView {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 60)
                    } else if filteredItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("No items found")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Try adjusting your filters or search")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredItems) { item in
                                NavigationLink {
                                    PostDetailView(item: item)
                                } label: {
                                    ItemCardView(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("All Items")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 24))
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? Color(red: 0.55, green: 0.60, blue: 0.85)
                        : Color(.systemGray6)
                )
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview
#Preview {
    AllItemsView()
        .environmentObject(PostViewModel())
}
