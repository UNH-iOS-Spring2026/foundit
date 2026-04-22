//
//  User.swift
//  foundit
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var displayName: String
    var email: String?
    var isAdmin: Bool?
    var createdAt: Timestamp?
    var updatedAt: Timestamp?  
    var nameChangedAt: Timestamp?
    
    // Custom initializer for decoding with defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        _id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID(wrappedValue: nil)
        displayName = try container.decode(String.self, forKey: .displayName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        isAdmin = try container.decodeIfPresent(Bool.self, forKey: .isAdmin) ?? false
        createdAt = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Timestamp.self, forKey: .updatedAt)
        nameChangedAt = try container.decodeIfPresent(Timestamp.self, forKey: .nameChangedAt)
    }
    
    // Regular initializer
    init(
        id: String? = nil,
        displayName: String,
        email: String? = nil,
        isAdmin: Bool = false,
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil,
        nameChangedAt: Timestamp? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.isAdmin = isAdmin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.nameChangedAt = nameChangedAt
    }
}
