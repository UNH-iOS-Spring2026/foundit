//
//  ClaimToken.swift
//  foundit
//

import Foundation
import FirebaseFirestore

struct ClaimToken: Identifiable, Codable {
    @DocumentID var id: String?
    var postId: String
    var itemId: String
    var nonce: String
    var expiresAt: Timestamp
    var consumedAt: Timestamp?
    var consumedByUserId: String?
    var createdByPoliceId: String
    var createdAt: Timestamp

    var isExpired: Bool {
        expiresAt.dateValue() <= Date()
    }

    var isConsumed: Bool {
        consumedAt != nil
    }
}
