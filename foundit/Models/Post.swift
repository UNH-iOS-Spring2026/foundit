//
//  Post.swift
//  foundit
//

import Foundation
import FirebaseFirestore

enum PostType: String, Codable {
    case lost
    case found
}

enum PostStatus: String, Codable {
    case open
    case matched
    case closed
}

struct Post: Identifiable, Codable {
    @DocumentID var id: String?
    var type: PostType
    var title: String
    var description: String
    var category: String
    var photoUrls: [String]
    var lastSeenLocation: GeoPoint
    var lastSeenLocationText: String
    var status: PostStatus
    var createdBy: String
    var createdAt: Timestamp
    var updatedAt: Timestamp
}
