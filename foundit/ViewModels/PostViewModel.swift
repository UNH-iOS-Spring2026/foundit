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
    @Published var reporterName: String = "Loading..."
    @Published var didSucceed = false

    private let postService = PostService()
    private let storageService = StorageService()
    private let userService = UserService()
    private let notificationService = NotificationService()

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

    func fetchUserPosts(userId: String? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            let resolvedUserId = userId ?? AppConfig.placeholderUserId
            userPosts = try await postService.fetchPostsByUser(userId: resolvedUserId)
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
    
    func fetchPostById(id: String) async throws -> Post? {
        return try await postService.fetchPostById(id: id)
    }

    func createPost(
        title: String,
        description: String,
        category: String,
        type: PostType,
        location: GeoPoint,
        locationText: String,
        photoData: [Data] = [],
        createdBy: String? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let postId = UUID().uuidString
            var photoUrls: [String] = []
            
            // Try to upload images, but don't fail if it doesn't work
            if !photoData.isEmpty {
                do {
                    photoUrls = try await storageService.uploadImages(dataArray: photoData, postId: postId)
                } catch {
                    // Continue without images instead of failing
                    errorMessage = "Post created, but image upload failed"
                }
            }

            let now = Timestamp()
            
            // Resolve the user ID
            let resolvedUserId = createdBy ?? AppConfig.placeholderUserId
            
            // Fetch reporter information
            var reporterInfo: Reporter? = nil
            if !resolvedUserId.isEmpty {
                do {
                    let user = try await userService.fetchUser(uid: resolvedUserId)
                    reporterInfo = Reporter(name: user.displayName, avatarUrl: nil)
                } catch {
                    // If we can't fetch user info, continue without it
                }
            }
            
            var post = Post(
                id: postId,
                type: type,
                title: title,
                description: description,
                category: category,
                photoUrls: photoUrls,  // Will be empty if upload failed
                lastSeenLocation: location,
                lastSeenLocationText: locationText,
                status: .open,
                createdBy: resolvedUserId,
                reporterInfo: reporterInfo,
                createdAt: now,
                updatedAt: now
            )
            
            // Create the post and get the actual Firebase document ID
            let firebaseDocumentId = try await postService.createPost(post)
            
            // Update the post object with the actual Firebase ID
            post.id = firebaseDocumentId
            
            // IMPORTANT: Find similar posts and notify users
            let similarPosts = try await postService.fetchSimilarPosts(to: post, limit: 10)
            await notificationService.notifyUsersOfSimilarPost(newPost: post, similarPosts: similarPosts)
            
            await fetchPosts()
            didSucceed = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func fetchReporterName(userId: String) async {
        guard !userId.isEmpty else {
            reporterName = "Unknown"
            return
        }
        
        do {
            let user = try await userService.fetchUser(uid: userId)
            reporterName = user.displayName
        } catch {
            reporterName = "Unknown"
        }
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
        existingPhotoUrls: [String] = [],
        reporterInfo: Reporter? = nil
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
                reporterInfo: reporterInfo,  // Preserve reporter info
                createdAt: Timestamp(), // This will be ignored in merge
                updatedAt: Timestamp()
            )
            
            try await postService.updatePost(id: id, post: updatedPost)
            await fetchPosts()
            didSucceed = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
