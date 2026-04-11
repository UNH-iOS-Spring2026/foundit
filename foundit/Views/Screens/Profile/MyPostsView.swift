//
//  MyPostsView.swift
//  foundit
//

import SwiftUI
import FirebaseAuth

struct MyPostsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var chatViewModel: ChatViewModel

    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var selectedFilter: PostType? = nil
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var postToDelete: Post? = nil
    @State private var showDeleteConfirmation = false
    @State private var postToEdit: Post? = nil
    @State private var navigateToEdit = false
    @State private var navigateToCreate = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var filteredPosts: [Post] {
        var result = posts
        if let filter = selectedFilter {
            result = result.filter { $0.type == filter }
        }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.lastSeenLocationText.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Filter bar - Only show if user has posts
            if !posts.isEmpty {
                HStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            MyPostsFilterPill(title: "All Items", isSelected: selectedFilter == nil) {
                                selectedFilter = nil
                            }
                            MyPostsFilterPill(title: "Lost", isSelected: selectedFilter == .lost) {
                                selectedFilter = .lost
                            }
                            MyPostsFilterPill(title: "Found", isSelected: selectedFilter == .found) {
                                selectedFilter = .found
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearch.toggle()
                        }
                        if !showSearch { searchText = "" }
                    } label: {
                        Image(systemName: showSearch ? "xmark.circle.fill" : "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // MARK: Search field
                if showSearch {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search your posts…", text: $searchText)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            // MARK: Content Area
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = errorMessage {
                Spacer()
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
                        Task { await loadPosts() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 32)
                Spacer()
            } else if posts.isEmpty {
                // MARK: Empty State - Centered with Create Button
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "tray")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("No posts yet")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Start by creating your first lost or found item post")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Button {
                        navigateToCreate = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Create Post")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.55, green: 0.60, blue: 0.85))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            } else {
                // MARK: Grid with ScrollView
                ScrollView {
                    if filteredPosts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("No items found")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Try a different filter or search")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredPosts) { item in
                                NavigationLink {
                                    PostDetailView(item: item, chatViewModel: chatViewModel)
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
                                        canDelete: true,
                                        canEdit: true
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
                .refreshable { await loadPosts() }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("My Posts")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToEdit) {
            if let post = postToEdit {
                PostItemView(postToEdit: post)
                    .environmentObject(postViewModel)
            }
        }
        .navigationDestination(isPresented: $navigateToCreate) {
            PostItemView(onPostCreated: {
                Task { await loadPosts() }
            })
                .environmentObject(postViewModel)
        }
        .onChange(of: navigateToEdit) { old, new in
            if old && !new {
                Task { await loadPosts() }
                postToEdit = nil
            }
        }
        .task { await loadPosts() }
        .alert("Delete Post", isPresented: $showDeleteConfirmation, presenting: postToDelete) { post in
            Button("Cancel", role: .cancel) { postToDelete = nil }
            Button("Delete", role: .destructive) {
                Task {
                    await deletePost(post)
                    postToDelete = nil
                }
            }
        } message: { post in
            Text("Are you sure you want to delete '\(post.title)'? This action cannot be undone.")
        }
    }

    // MARK: - Data

    private func loadPosts() async {
        guard let uid = authVM.currentUser?.uid else { return }
        isLoading = true
        errorMessage = nil
        do {
            posts = try await PostService().fetchPostsByUser(userId: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func deletePost(_ post: Post) async {
        guard let id = post.id else { return }
        do {
            try await PostService().deletePost(id: id)
            posts.removeAll { $0.id == id }
        } catch {
            print("[MyPosts] Delete error: \(error)")
        }
    }
}

// MARK: - Filter Pill

private struct MyPostsFilterPill: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? Color(red: 0.55, green: 0.60, blue: 0.85)
                        : Color(.systemGray5)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MyPostsView()
            .environmentObject(AuthViewModel())
            .environmentObject(PostViewModel())
    }
}
