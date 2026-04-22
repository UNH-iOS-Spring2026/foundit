//
//  ClaimToken.swift
//  foundit
//
//  Firestore record that backs a single QR claim.
//  Written by the police phone when generating a QR, consumed by the
//  student's phone when they scan it. Storing it server-side is what
//  makes the QR verifiable — the scanner looks up this document to
//  confirm the code is real, unexpired, and unused.
//

import Foundation
import FirebaseFirestore

/// A single QR claim record, stored in the top-level `claimTokens` collection.
///
/// Document ID is the `nonce` so the scanner can find the token in one read.
struct ClaimToken: Identifiable, Codable {
    @DocumentID var id: String?

    /// The post this claim is for.
    var postId: String
    /// The physical item being returned.
    var itemId: String
    /// Unique identifier for this claim (also used as the doc ID).
    var nonce: String
    /// Time after which the QR should no longer be accepted.
    var expiresAt: Timestamp
    /// Filled in when the student scans and redeems the code.
    var consumedAt: Timestamp?
    /// UID of the student who scanned it. Nil until redeemed.
    var consumedByUserId: String?
    /// UID of the officer who generated the code.
    var createdByPoliceId: String
    /// When the QR was generated.
    var createdAt: Timestamp

    /// True once the TTL has passed.
    var isExpired: Bool {
        expiresAt.dateValue() <= Date()
    }

    /// True once the token has been redeemed by a scan.
    var isConsumed: Bool {
        consumedAt != nil
    }
}
