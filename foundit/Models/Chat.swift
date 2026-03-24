//
//  Chat.swift
//  foundit
//

import Foundation
import FirebaseFirestore

struct Chat: Identifiable, Codable {
    @DocumentID var id: String?
    var postId: String
    var userId: String
    var policeId: String
    var lastMessage: String
    var lastMessageAt: Timestamp
    var createdAt: Timestamp
    var updatedAt: Timestamp
}

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var senderId: String
    var text: String
    var sentAt: Timestamp
}
