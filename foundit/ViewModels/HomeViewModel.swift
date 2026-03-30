//
//  HomeViewModel.swift
//  foundit
//
//  Created by Divya Panthi on 17/03/2026.
//

import Foundation
import Combine
 
@MainActor
final class HomeViewModel: ObservableObject {
 
    // MARK: Published State
    @Published var items: [Post] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: Services
    private let postService = PostService()
 
    // MARK: filtered items
    var filteredItems: [Post] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return items
        }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.lastSeenLocationText.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }
 
    // MARK: Init
    init() {
        Task {
            await loadItems()
        }
    }
 
    // MARK: Load items from backend
    func loadItems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await postService.fetchPosts()
        } catch {
            errorMessage = error.localizedDescription
            items = []
        }
        
        isLoading = false
    }
    
    // MARK: Refresh items
    func refreshItems() async {
        await loadItems()
    }
    
    // MARK: Filter by type
    func loadItems(ofType type: PostType) async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await postService.fetchPosts(type: type)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: Delete post
    func deletePost(_ post: Post) async {
        guard let postId = post.id else {
            errorMessage = "Cannot delete post: missing ID"
            return
        }
        
        do {
            try await postService.deletePost(id: postId)
            // Remove from local array for immediate UI update
            items.removeAll { $0.id == postId }
        } catch {
            errorMessage = "Failed to delete post: \(error.localizedDescription)"
        }
    }
}
 
