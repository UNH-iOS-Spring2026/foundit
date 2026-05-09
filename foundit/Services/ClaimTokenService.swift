//
//  ClaimTokenService.swift
//  foundit
//
//  Talks to the `claimTokens` Firestore collection.
//  Handles creating a token (police side), parsing the scanned QR,
//  redeeming the token atomically (student side), and a real-time
//  listener the police uses to know when the student has scanned.
//

import Foundation
import FirebaseFirestore

/// User-facing errors that can happen during the claim flow.
/// The scanner result sheet shows `errorDescription` directly.
enum ClaimTokenError: LocalizedError {
    case invalidPayload       // QR didn't parse as a foundit-claim URL
    case tokenNotFound        // No matching document in Firestore
    case expired              // Past expiresAt
    case alreadyConsumed      // Someone already scanned this one
    case itemNotFound         // The linked items/<id> doc is gone

    var errorDescription: String? {
        switch self {
        case .invalidPayload:    return "This QR code isn't a valid foundit claim code."
        case .tokenNotFound:     return "This claim code wasn't recognized."
        case .expired:           return "This claim code has expired. Please ask the officer to generate a new one."
        case .alreadyConsumed:   return "This claim code has already been used."
        case .itemNotFound:      return "The item linked to this code could not be found."
        }
    }
}

class ClaimTokenService {
    private let db = Firestore.firestore()
    private let collection = "claimTokens"

    /// Police side — writes a new claim token to Firestore so the scanner
    /// can verify it later. The doc ID is the nonce.
    func createToken(
        postId: String,
        itemId: String,
        nonce: String,
        expiresAt: Date,
        createdByPoliceId: String
    ) async throws {
        let token = ClaimToken(
            id: nonce,
            postId: postId,
            itemId: itemId,
            nonce: nonce,
            expiresAt: Timestamp(date: expiresAt),
            consumedAt: nil,
            consumedByUserId: nil,
            createdByPoliceId: createdByPoliceId,
            createdAt: Timestamp()
        )
        try db.collection(collection).document(nonce).setData(from: token)
    }

    /// Looks up a token by its nonce. Thrown `tokenNotFound` means the
    /// scanner read a string that doesn't match any issued code.
    func fetchToken(nonce: String) async throws -> ClaimToken {
        let doc = try await db.collection(collection).document(nonce).getDocument()
        guard doc.exists, let token = try? doc.data(as: ClaimToken.self) else {
            throw ClaimTokenError.tokenNotFound
        }
        return token
    }

    /// Parses a `foundit-claim://v1?postId=...&nonce=...&exp=...` URL and returns the nonce.
    static func parseNonce(from raw: String) -> String? {
        guard let url = URL(string: raw),
              url.scheme == "foundit-claim",
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let nonce = comps.queryItems?.first(where: { $0.name == "nonce" })?.value,
              !nonce.isEmpty
        else { return nil }
        return nonce
    }

    /// In a single batch, marks the token consumed and flips the linked item to `.returned`.
    /// Also closes the matching chat and posts a system message if a chat exists.
    /// Returns the `chatId` of the closed chat (if any) so callers can navigate to it.
    @discardableResult
    func redeemToken(
        _ token: ClaimToken,
        consumedByUserId: String,
        returnLocation: GeoPoint? = nil
    ) async throws -> String? {
        guard !token.isConsumed else { throw ClaimTokenError.alreadyConsumed }
        guard !token.isExpired  else { throw ClaimTokenError.expired }

        let now = Timestamp()
        let batch = db.batch()

        // 1. Mark token consumed
        let tokenRef = db.collection(collection).document(token.nonce)
        batch.updateData([
            "consumedAt": now,
            "consumedByUserId": consumedByUserId
        ], forDocument: tokenRef)

        // 2. Flip item to returned
        let itemRef = db.collection("items").document(token.itemId)
        let itemDoc = try await itemRef.getDocument()
        guard itemDoc.exists else { throw ClaimTokenError.itemNotFound }
        var itemUpdate: [String: Any] = [
            "status": ItemStatus.returned.rawValue,
            "returnedAt": now,
            "returnedByUserId": consumedByUserId
        ]
        if let loc = returnLocation {
            itemUpdate["returnLocation"] = loc
        }
        batch.updateData(itemUpdate, forDocument: itemRef)

        // 3. Close the chat + post a system message if a chat exists for this post/user
        var resolvedChatId: String?
        let chatSnap = try await db.collection("chats")
            .whereField("postId", isEqualTo: token.postId)
            .whereField("userId", isEqualTo: consumedByUserId)
            .limit(to: 1)
            .getDocuments()
        if let chatDoc = chatSnap.documents.first {
            resolvedChatId = chatDoc.documentID
            batch.updateData([
                "status": Chat.Status.closed.rawValue,
                "lastMessage": "Item returned to owner.",
                "lastMessageAt": now,
                "updatedAt": now
            ], forDocument: chatDoc.reference)

            let msgRef = chatDoc.reference.collection("messages").document()
            let sysMsg = Message(
                senderId: "system",
                senderRole: .system,
                type: .system,
                text: "Item returned to owner.",
                photoUrl: nil,
                sentAt: now
            )
            try batch.setData(from: sysMsg, forDocument: msgRef)
        }

        try await batch.commit()
        return resolvedChatId
    }

    /// Real-time listener: fires when the token at `nonce` is consumed.
    /// Returns a handle so callers can detach.
    func observeConsumption(
        nonce: String,
        onConsumed: @escaping (_ consumedByUserId: String) -> Void
    ) -> ListenerRegistration {
        db.collection(collection).document(nonce)
            .addSnapshotListener { snapshot, _ in
                guard let data = snapshot?.data(),
                      data["consumedAt"] is Timestamp,
                      let consumedByUserId = data["consumedByUserId"] as? String,
                      !consumedByUserId.isEmpty
                else { return }
                onConsumed(consumedByUserId)
            }
    }
}
