//
//  PostViewModel.swift
//  foundit
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class PostViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var userPosts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let postService = PostService()
    private let storageService = StorageService()

    func fetchPosts(type: PostType? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            posts = try await postService.fetchPosts(type: type)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func fetchUserPosts(userId: String = AppConfig.placeholderUserId) async {
        isLoading = true
        errorMessage = nil
        do {
            userPosts = try await postService.fetchPostsByUser(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func fetchSimilarPosts(to post: Post, limit: Int = 6) async -> [Post] {
        do {
            let similar = try await postService.fetchSimilarPosts(to: post, limit: limit)
            return similar
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }

    func createPost(
        title: String,
        description: String,
        category: String,
        type: PostType,
        location: GeoPoint,
        locationText: String,
        photoData: [Data] = [],
        createdBy: String = AppConfig.placeholderUserId
    ) async {
        isLoading = true
        errorMessage = nil
        do {
            let postId = UUID().uuidString
            var photoUrls: [String] = []
            if !photoData.isEmpty {
                photoUrls = try await storageService.uploadImages(dataArray: photoData, postId: postId)
            }

            let now = Timestamp()
            let post = Post(
                type: type,
                title: title,
                description: description,
                category: category,
                photoUrls: photoUrls,
                lastSeenLocation: location,
                lastSeenLocationText: locationText,
                status: .open,
                createdBy: createdBy,
                createdAt: now,
                updatedAt: now
            )
            _ = try await postService.createPost(post)
            await fetchPosts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deletePost(id: String) async {
        do {
            try await postService.deletePost(id: id)
            posts.removeAll { $0.id == id }
            userPosts.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updatePost(
        id: String,
        title: String,
        description: String,
        category: String,
        type: PostType,
        location: GeoPoint,
        locationText: String,
        photoData: [Data] = [],
        existingPhotoUrls: [String] = []
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            var photoUrls = existingPhotoUrls
            
            // Upload new images if provided
            if !photoData.isEmpty {
                do {
                    let newUrls = try await storageService.uploadImages(dataArray: photoData, postId: id)
                    photoUrls.append(contentsOf: newUrls)
                } catch {
                    errorMessage = "Post updated, but new image upload failed"
                }
            }
            
            let updatedPost = Post(
                id: id,
                type: type,
                title: title,
                description: description,
                category: category,
                photoUrls: photoUrls,
                lastSeenLocation: location,
                lastSeenLocationText: locationText,
                status: .open,
                createdBy: AppConfig.placeholderUserId,
                createdAt: Timestamp(), // This will be ignored in merge
                updatedAt: Timestamp()
            )
            
            try await postService.updatePost(id: id, post: updatedPost)
            await fetchPosts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
