//
//  ItemService.swift
//  foundit
//

import Foundation
import FirebaseFirestore

class ItemService {
    private let db = Firestore.firestore()
    private let collection = "items"

    func createItem(_ item: Item) async throws -> String {
        let ref = try db.collection(collection).addDocument(from: item)
        return ref.documentID
    }

    func fetchItem(id: String) async throws -> Item {
        let doc = try await db.collection(collection).document(id).getDocument()
        guard let item = try doc.data(as: Item.self) as Item? else {
            throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
        }
        return item
    }

    func fetchItemByQR(qrValue: String) async throws -> Item? {
        let snapshot = try await db.collection(collection)
            .whereField("qrCodeValue", isEqualTo: qrValue)
            .limit(to: 1)
            .getDocuments()
        return try snapshot.documents.first.map { try $0.data(as: Item.self) }
    }

    func fetchItemsByPost(postId: String) async throws -> [Item] {
        let snapshot = try await db.collection(collection)
            .whereField("sourcePostId", isEqualTo: postId)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Item.self) }
    }

    func updateItemStatus(id: String, status: ItemStatus) async throws {
        var data: [String: Any] = ["status": status.rawValue]
        if status == .returned {
            data["returnedAt"] = Timestamp()
        }
        try await db.collection(collection).document(id).updateData(data)
    }
}
