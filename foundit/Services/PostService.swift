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

        // If filtering by type, add the where clause (don't order in query to avoid needing composite index)
        if let type {
            query = query.whereField("type", isEqualTo: type.rawValue)
        } else {
            // Only order in the query when NOT filtering by type
            query = query.order(by: "createdAt", descending: true)
        }

        let snapshot = try await query.getDocuments()
        
        var posts: [Post] = []
        for document in snapshot.documents {
            do {
                var post = try document.data(as: Post.self)
                // Ensure the ID is set (fallback if @DocumentID doesn't work)
                if post.id == nil || post.id?.isEmpty == true {
                    post.id = document.documentID
                }
                posts.append(post)
            } catch {
                // Skip documents that can't be decoded
                continue
            }
        }
        
        // Sort in memory when we filtered by type (to avoid needing composite index)
        if type != nil {
            posts.sort { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
        }
        
        return posts
    }
    
    func fetchPostById(id: String) async throws -> Post? {
        let document = try await db.collection(collection).document(id).getDocument()
        
        guard document.exists else {
            return nil
        }
        
        var post = try document.data(as: Post.self)
        // Ensure the ID is set
        if post.id == nil || post.id?.isEmpty == true {
            post.id = document.documentID
        }
        return post
    }

    func fetchPostsByUser(userId: String) async throws -> [Post] {
        // Fetch posts by user (don't order in query to avoid needing composite index)
        let snapshot = try await db.collection(collection)
            .whereField("createdBy", isEqualTo: userId)
            .getDocuments()
        
        var posts: [Post] = []
        for document in snapshot.documents {
            do {
                var post = try document.data(as: Post.self)
                // Ensure the ID is set
                if post.id == nil || post.id?.isEmpty == true {
                    post.id = document.documentID
                }
                posts.append(post)
            } catch {
                continue
            }
        }
        
        // Sort in memory by creation date
        posts.sort { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
        return posts
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
        
        // Fetch posts with the same category only
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
                                
                // Skip the current post itself
                if fetchedPost.id != post.id {
                    posts.append(fetchedPost)
                }
            } catch {
                print("Failed to decode document: \(error.localizedDescription)")
                continue
            }
        }
        
        // Sort by creation date in memory and limit results
        let sortedPosts = posts.sorted { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
        let limitedPosts = Array(sortedPosts.prefix(limit))
        return limitedPosts
    }
}
