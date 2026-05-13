//
//  User.swift
//  foundit
//
//  Written by Rohan Poudel, assisted by Claude.
//
//  Application user profile stored in the `users` Firestore collection.
//  Mirrors the Firebase Auth account by UID and adds the app-specific
//  display fields (name, avatar, admin flag) the UI needs.
//

import Foundation
import FirebaseFirestore

/// User profile document. The `id` matches the Firebase Auth UID, which is
/// what every other collection refers to when storing `createdBy` / `userId`.
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var displayName: String
    var email: String?
    /// True for police/admin accounts. Drives which tab bar is shown at launch.
    var isAdmin: Bool?
    /// Firebase Storage URL for the avatar image.
    var avatarUrl: String?
    var createdAt: Timestamp?
    var updatedAt: Timestamp?
    /// Last time displayName was changed. Used to rate-limit renames.
    var nameChangedAt: Timestamp?

    // Custom decoding path: tolerates documents missing optional fields
    // and defaults isAdmin to false rather than throwing.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        _id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID(wrappedValue: nil)
        displayName = try container.decode(String.self, forKey: .displayName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        isAdmin = try container.decodeIfPresent(Bool.self, forKey: .isAdmin) ?? false
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        createdAt = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Timestamp.self, forKey: .updatedAt)
        nameChangedAt = try container.decodeIfPresent(Timestamp.self, forKey: .nameChangedAt)
    }
    
    // Convenience initializer used when creating profiles in code.
    init(
        id: String? = nil,
        displayName: String,
        email: String? = nil,
        isAdmin: Bool = false,
        avatarUrl: String? = nil,
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil,
        nameChangedAt: Timestamp? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.isAdmin = isAdmin
        self.avatarUrl = avatarUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.nameChangedAt = nameChangedAt
    }
}
