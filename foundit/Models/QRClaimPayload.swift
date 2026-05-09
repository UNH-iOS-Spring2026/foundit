//
//  QRClaimPayload.swift
//  foundit
//
//  Represents the data encoded inside a QR code for the claim flow.
//  The police phone generates one of these every time "Show QR Code"
//  is tapped, and the resulting string is what gets drawn as the QR.
//

import Foundation

/// The payload embedded in a claim QR code.
///
/// Each claim is identified by a unique `nonce` (UUID) so the code can
/// only be used once, and is given a short `expiresAt` so it's time-limited.
/// The encoded form is a custom URL scheme the scanner can parse later.
struct QRClaimPayload {
    /// The post this claim is tied to.
    let postId: String
    /// A fresh UUID used as the one-time identifier for this claim.
    let nonce: String
    /// When the code becomes invalid (default: 5 minutes from generation).
    let expiresAt: Date

    /// The string that actually gets drawn into the QR image.
    /// Format: `foundit-claim://v1?postId=<id>&nonce=<uuid>&exp=<unix_ts>`
    var encoded: String {
        let exp = Int(expiresAt.timeIntervalSince1970)
        return "foundit-claim://v1?postId=\(postId)&nonce=\(nonce)&exp=\(exp)"
    }

    /// Builds a new claim payload for the given post.
    /// - Parameters:
    ///   - postId: the post this claim belongs to.
    ///   - ttl: how long the code is valid for, in seconds. Defaults to 5 minutes.
    static func generate(for postId: String, ttl: TimeInterval = 300) -> QRClaimPayload {
        QRClaimPayload(
            postId: postId,
            nonce: UUID().uuidString,
            expiresAt: Date().addingTimeInterval(ttl)
        )
    }
}
