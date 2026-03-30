//
//  PostService.swift
//  foundit
//

import Foundation
import FirebaseFirestore

class PostService {
    private let db = Firestore.firestore()
    private let collection = "posts"

    func createPost(_ post: Post) async throws -> String {
        let ref = try db.collection(collection).addDocument(from: post)
        return ref.documentID
    }

    func fetchPosts(type: PostType? = nil) async throws -> [Post] {
        var query: Query = db.collection(collection)
            .order(by: "createdAt", descending: true)

        if let type {
            query = query.whereField("type", isEqualTo: type.rawValue)
        }

        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Post.self) }
    }

    func fetchPostsByUser(userId: String) async throws -> [Post] {
        let snapshot = try await db.collection(collection)
            .whereField("createdBy", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Post.self) }
    }

    func updatePostStatus(id: String, status: PostStatus) async throws {
        try await db.collection(collection).document(id).updateData([
            "status": status.rawValue,
            "updatedAt": Timestamp()
        ])
    }

    func deletePost(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
    
    func updatePost(id: String, post: Post) async throws {
        try db.collection(collection).document(id).setData(from: post, merge: true)
    }
    
    func fetchSimilarPosts(to post: Post, limit: Int = 6) async throws -> [Post] {
        print("Fetching similar posts: '\(post.category)'")
        
        // First try: Fetch posts with the same category
        let categoryQuery: Query = db.collection(collection)
            .whereField("category", isEqualTo: post.category)
        
        let categorySnapshot = try await categoryQuery.getDocuments()
        
        var posts: [Post] = []
        for document in categorySnapshot.documents {
            do {
                var fetchedPost = try document.data(as: Post.self)
                // Ensure the ID is set
                if fetchedPost.id == nil || fetchedPost.id?.isEmpty == true {
                    fetchedPost.id = document.documentID
                }
                
                print("-Found post: \(fetchedPost.title) (ID: \(fetchedPost.id ?? "nil"), Category: \(fetchedPost.category))")
                
                // Skip the current post itself
                if fetchedPost.id != post.id {
                    posts.append(fetchedPost)
                }
            } catch {
                print("Failed to decode document: \(error.localizedDescription)")
                continue
            }
        }
        
        // If we don't have enough posts from the same category, fetch some recent posts
        if posts.count < limit {
            let allPostsQuery: Query = db.collection(collection)
                .order(by: "createdAt", descending: true)
                .limit(to: limit + 5)
            
            let allSnapshot = try await allPostsQuery.getDocuments()
            
            for document in allSnapshot.documents {
                do {
                    var fetchedPost = try document.data(as: Post.self)
                    if fetchedPost.id == nil || fetchedPost.id?.isEmpty == true {
                        fetchedPost.id = document.documentID
                    }
                    
                    // Add if not already in the list and not the current post
                    if fetchedPost.id != post.id && !posts.contains(where: { $0.id == fetchedPost.id }) {
                        posts.append(fetchedPost)
                    }
                    
                    // Stop if we have enough
                    if posts.count >= limit {
                        break
                    }
                } catch {
                    continue
                }
            }
        }
        
        // Sort by creation date in memory and limit results
        let sortedPosts = posts.sorted { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
        let limitedPosts = Array(sortedPosts.prefix(limit))
        return limitedPosts
    }
}
