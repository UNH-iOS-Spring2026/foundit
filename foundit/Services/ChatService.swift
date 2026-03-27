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

    func fetchChats(forUserId userId: String) async throws -> [Chat] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
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
        batch.updateData([
            "lastMessage": message.text,
            "lastMessageAt": message.sentAt,
            "updatedAt": message.sentAt
        ], forDocument: chatRef)

        try await batch.commit()
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
