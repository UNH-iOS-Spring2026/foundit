//
//  Item.swift
//  foundit
//

import Foundation
import FirebaseFirestore

enum ItemStatus: String, Codable {
    case withAdmin = "with_admin"
    case waitingForPickup = "waiting_for_pickup"
    case returned
}

struct Item: Identifiable, Codable {
    @DocumentID var id: String?
    var sourcePostId: String
    var status: ItemStatus
    var qrCodeValue: String
    var receivedAt: Timestamp
    var returnedAt: Timestamp?
    var foundBy: String
    var collectedBy: String
}

struct Location: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var addressText: String
    var geo: GeoPoint
    var managedBy: [String]
    var isActive: Bool
    var createdAt: Timestamp
    var updatedAt: Timestamp
}
