//
//  HomeViewModel.swift
//  foundit
//
//  Created by Divya Panthi on 17/03/2026.
//

import Foundation
import Combine
 

final class HomeViewModel: ObservableObject {
 
    // MARK: Published State
    @Published var items: [LostFoundItem] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
 
    // MARK: filtered items
    var filteredItems: [LostFoundItem] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return items
        }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
 
    // MARK: Init
    init() {
        loadItems()
    }
 
    // MARK: Load (replace with real API/repo call)
    func loadItems() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.items = LostFoundItem.mockItems
            self?.isLoading = false
        }
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
    
    // MARK: Update post
    func updatePost(_ post: Post) async {
        guard let postId = post.id else {
            errorMessage = "Cannot update post: missing ID"
            return
        }
        
        do {
            try await postService.updatePost(id: postId, post: post)
            // Refresh items to show updated post
            await loadItems()
        } catch {
            errorMessage = "Failed to update post: \(error.localizedDescription)"
        }
    }
}
 
