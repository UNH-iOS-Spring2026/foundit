//
//  User.swift
//  foundit
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var displayName: String
    var email: String
    var isAdmin: Bool
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var nameChangedAt: Timestamp?
}
