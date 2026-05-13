//
//  Item.swift
//  foundit
//
//  Written by Rohan Poudel, assisted by Claude.
//
//  Represents a physical found object once police have it in custody —
//  separate from the user-visible `Post` that describes it. The QR claim
//  flow updates this record (status, returnedAt, returnedByUserId) when
//  a student scans and successfully redeems a claim token.
//

import Foundation
import FirebaseFirestore

/// Lifecycle of a physical item inside the police inventory.
/// `returned` is terminal and is set atomically by `ClaimTokenService.redeemToken`.
enum ItemStatus: String, Codable {
    case withAdmin = "with_admin"
    case waitingForPickup = "waiting_for_pickup"
    case returned
}

/// A physical item in police custody. Lives in the `items` Firestore collection.
struct Item: Identifiable, Codable {
    @DocumentID var id: String?
    /// The post that triggered this intake (lost report or found report).
    var sourcePostId: String
    var status: ItemStatus
    /// Stable identifier used to print/display the QR tag on the item.
    var qrCodeValue: String
    var receivedAt: Timestamp
    /// Set when the QR claim flow marks the item returned.
    var returnedAt: Timestamp?
    /// UID of whoever first reported finding the item.
    var foundBy: String
    /// UID of the officer who took the item into inventory.
    var collectedBy: String
    /// UID of the student who scanned the QR to claim the item. Set at return time.
    var returnedByUserId: String?
    /// Optional location where the return was completed. Set at return time.
    var returnLocation: GeoPoint?
}

/// A pickup/drop-off site managed by one or more police officers.
/// Used when surfacing return locations to students in the UI.
struct Location: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var addressText: String
    var geo: GeoPoint
    /// UIDs of officers who manage this location.
    var managedBy: [String]
    var isActive: Bool
    var createdAt: Timestamp
    var updatedAt: Timestamp
}
