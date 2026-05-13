//
//  UserService.swift
//  foundit
//

import Foundation
import FirebaseFirestore

class UserService {
    private let db = Firestore.firestore()
    private let collection = "users"

    func fetchUser(uid: String) async throws -> User {
        let snapshot = try await db.collection(collection).document(uid).getDocument()
        return try snapshot.data(as: User.self)
    }

    func updateAvatarUrl(uid: String, url: String) async throws {
        try await db.collection(collection).document(uid).updateData([
            "avatarUrl": url,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
}
