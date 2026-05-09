//
//  PoliceDashboardView.swift
//  foundit
//

import SwiftUI

struct PoliceDashboardView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var chatViewModel: ChatViewModel
    @State private var selectedFilter: PostType? = nil
    @State private var showFilterSheet = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Police Dashboard")
                        .font(.system(size: 22, weight: .bold))
                    Text("\(viewModel.filteredItems.count) reports")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(red: 0.55, green: 0.60, blue: 0.85))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search reports...", text: $viewModel.searchText)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
            .padding(.horizontal, 16)

            // Content
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 60)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await viewModel.loadItems() }
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
                        Text("No reports found")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.filteredItems) { item in
                            NavigationLink {
                                PostDetailView(item: item, chatViewModel: chatViewModel)
                            } label: {
                                ItemCardView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }
            .refreshable {
                await viewModel.refreshItems()
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
    }
}

#Preview {
    NavigationStack {
        PoliceDashboardView()
            .environmentObject(ChatViewModel())
    }
}
