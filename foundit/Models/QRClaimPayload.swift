//
//  QRClaimPayload.swift
//  foundit
//

import Foundation

struct QRClaimPayload {
    let postId: String
    let nonce: String
    let expiresAt: Date

    var encoded: String {
        let exp = Int(expiresAt.timeIntervalSince1970)
        return "foundit-claim://v1?postId=\(postId)&nonce=\(nonce)&exp=\(exp)"
    }

    static func generate(for postId: String, ttl: TimeInterval = 300) -> QRClaimPayload {
        QRClaimPayload(
            postId: postId,
            nonce: UUID().uuidString,
            expiresAt: Date().addingTimeInterval(ttl)
        )
    }
}
