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
}
