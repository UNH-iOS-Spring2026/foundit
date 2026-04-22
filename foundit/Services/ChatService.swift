//
//  ChatService.swift
//  foundit
//

import Foundation
import FirebaseFirestore
import Combine

class ChatService {
    private let db = Firestore.firestore()
    private let collection = "chats"

    func createChat(_ chat: Chat) async throws -> String {
        let ref = try db.collection(collection).addDocument(from: chat)
        return ref.documentID
    }

    func fetchChat(forPostId postId: String, userId: String) async throws -> Chat? {
        let snapshot = try await db.collection(collection)
            .whereField("postId", isEqualTo: postId)
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()
        return try snapshot.documents.first.map { try $0.data(as: Chat.self) }
    }

    func fetchChats(forUserId userId: String) async throws -> [Chat] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "lastMessageAt", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Chat.self) }
    }

    /// Fetches all chats for the police shared inbox (all conversations).
    func fetchAllPoliceChats() async throws -> [Chat] {
        let snapshot = try await db.collection(collection)
            .order(by: "lastMessageAt", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Chat.self) }
    }

    func sendMessage(chatId: String, message: Message) async throws {
        let batch = db.batch()

        let msgRef = db.collection(collection)
            .document(chatId)
            .collection("messages")
            .document()
        try batch.setData(from: message, forDocument: msgRef)

        let chatRef = db.collection(collection).document(chatId)
        let lastMessageText = message.type == .photo ? "Photo" : message.text
        batch.updateData([
            "lastMessage": lastMessageText,
            "lastMessageAt": message.sentAt,
            "updatedAt": message.sentAt
        ], forDocument: chatRef)

        try await batch.commit()
    }

    /// Mark a chat as waiting for pickup, update (or create) the linked item, and post a system message.
    /// Creates an `Item` doc if none exists so downstream claim-token flow has an `itemId` to reference.
    func markReadyForPickup(chatId: String, postId: String) async throws {
        let batch = db.batch()
        let now = Timestamp()

        // Fetch the chat once so we can capture user/police IDs for a new item if needed.
        let chatDoc = try await db.collection(collection).document(chatId).getDocument()
        let chat = try? chatDoc.data(as: Chat.self)

        // Update chat status
        let chatRef = db.collection(collection).document(chatId)
        batch.updateData([
            "status": Chat.Status.waitingForPickup.rawValue,
            "lastMessage": "This item has been marked as ready for pickup at the police station.",
            "lastMessageAt": now,
            "updatedAt": now
        ], forDocument: chatRef)

        // Update existing item, or provision a new one.
        let itemSnapshot = try await db.collection("items")
            .whereField("sourcePostId", isEqualTo: postId)
            .limit(to: 1)
            .getDocuments()
        if let itemDoc = itemSnapshot.documents.first {
            batch.updateData([
                "status": ItemStatus.waitingForPickup.rawValue
            ], forDocument: itemDoc.reference)
        } else {
            let itemRef = db.collection("items").document()
            let newItem = Item(
                sourcePostId: postId,
                status: .waitingForPickup,
                qrCodeValue: UUID().uuidString,
                receivedAt: now,
                returnedAt: nil,
                foundBy: chat?.userId ?? "",
                collectedBy: chat?.policeId ?? AppConfig.policeSenderId
            )
            try batch.setData(from: newItem, forDocument: itemRef)
        }

        // Post system message
        let msgRef = db.collection(collection)
            .document(chatId)
            .collection("messages")
            .document()
        let systemMessage = Message(
            senderId: "system",
            senderRole: .system,
            type: .system,
            text: "This item has been marked as ready for pickup at the police station.",
            photoUrl: nil,
            sentAt: now
        )
        try batch.setData(from: systemMessage, forDocument: msgRef)

        try await batch.commit()
    }

    func chatPublisher(chatId: String) -> AnyPublisher<Chat?, Error> {
        let subject = PassthroughSubject<Chat?, Error>()
        db.collection(collection).document(chatId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                } else if let snapshot = snapshot {
                    let chat = try? snapshot.data(as: Chat.self)
                    subject.send(chat)
                }
            }
        return subject.eraseToAnyPublisher()
    }

    func messagesPublisher(chatId: String) -> AnyPublisher<[Message], Error> {
        let query = db.collection(collection)
            .document(chatId)
            .collection("messages")
            .order(by: "sentAt", descending: false)

        let subject = PassthroughSubject<[Message], Error>()
        query.addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
            } else if let snapshot = snapshot {
                let messages = snapshot.documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                }
                subject.send(messages)
            }
        }
        return subject.eraseToAnyPublisher()
    }
}
