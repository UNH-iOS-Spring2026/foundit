//
//  Chat.swift
//  foundit
//

import Foundation
import FirebaseFirestore

struct Chat: Identifiable, Codable, Hashable {
    static func == (lhs: Chat, rhs: Chat) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    enum Status: String, Codable {
        case active
        case closed
    }

    @DocumentID var id: String?
    var postId: String
    var userId: String
    var policeId: String

    // Item metadata for inbox display
    var itemTitle: String
    var itemImageUrl: String?

    // Conversation metadata
    var lastMessage: String
    var lastMessageAt: Timestamp
    var status: Status = .active

    // Auditing
    var createdAt: Timestamp
    var updatedAt: Timestamp
}

struct Message: Identifiable, Codable {
    enum MessageType: String, Codable {
        case text
        case photo
    }

    enum SenderRole: String, Codable {
        case student
        case police
    }

    @DocumentID var id: String?
    var senderId: String
    var senderRole: SenderRole
    var type: MessageType
    var text: String
    var photoUrl: String?
    var sentAt: Timestamp
}
