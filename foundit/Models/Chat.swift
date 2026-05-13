//
//  Chat.swift
//  foundit
//
//  Written by Rohan Poudel, assisted by Claude.
//
//  Firestore-backed conversation between a student and the police about
//  a single post. Each chat has a sub-collection of `Message` documents.
//  Status transitions: active → waitingForPickup → closed (closed is set
//  by the QR claim flow once the item is returned).
//

import Foundation
import FirebaseFirestore

/// One conversation thread. Document lives in the top-level `chats` collection
/// and the message history lives under `chats/<id>/messages`.
struct Chat: Identifiable, Codable, Hashable {
    static func == (lhs: Chat, rhs: Chat) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Lifecycle of a chat. `closed` is the terminal state once the item
    /// is handed off (set by the QR claim flow in ClaimTokenService).
    enum Status: String, Codable {
        case active
        case waitingForPickup
        case closed
    }

    @DocumentID var id: String?
    /// The post this conversation is about — links the chat back to the item.
    var postId: String
    /// UID of the student participant.
    var userId: String
    /// UID of the police officer handling this post.
    var policeId: String

    // Item metadata duplicated here so the inbox list can render rows
    // without an extra read against the `posts` collection.
    var itemTitle: String
    var itemImageUrl: String?

    // Conversation metadata used by the inbox to show the latest snippet.
    var lastMessage: String
    var lastMessageAt: Timestamp
    var status: Status = .active

    // Auditing fields used for sorting and lifecycle tracking.
    var createdAt: Timestamp
    var updatedAt: Timestamp
}

/// A single message inside a chat. Stored under `chats/<chatId>/messages`.
struct Message: Identifiable, Codable {
    /// What kind of content the message carries. `system` is reserved for
    /// auto-generated entries like "Item returned to owner."
    enum MessageType: String, Codable {
        case text
        case photo
        case system
    }

    /// Who sent the message. `system` messages have no real author.
    enum SenderRole: String, Codable {
        case student
        case police
        case system
    }

    @DocumentID var id: String?
    /// UID of the sender. For system messages this is the literal string "system".
    var senderId: String
    var senderRole: SenderRole
    var type: MessageType
    /// Text body. For photo messages this can hold a caption.
    var text: String
    /// Firebase Storage URL for photo messages; nil otherwise.
    var photoUrl: String?
    var sentAt: Timestamp
}
