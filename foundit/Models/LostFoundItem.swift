//
//  LostFoundItem.swift (DEPRECATED - Use Post.swift instead)
//  foundit
//
//  Created by Divya Panthi on 17/03/2026.
//
//  This file is kept for reference only.
//  All models have been migrated to Post.swift to work with Firebase backend.

/*
import Foundation
import UIKit

// LEGACY CODE - DO NOT USE
// This was the original local model before Firebase integration
// All functionality has been moved to Post.swift

enum OldPostStatus {
    case lost
    case found
 
    var label: String {
        switch self {
        case .lost:  return "Lost"
        case .found: return "Found"
        }
    }
}

// MARK: Reporter
struct OldReporter: Identifiable {
    let id: UUID
    let name: String
    let avatarName: String        // Asset catalog image name
 
    init(id: UUID = UUID(), name: String, avatarName: String) {
        self.id = id
        self.name = name
        self.avatarName = avatarName
    }
}

struct OldPost: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let imageName: String
    let images: [String]  // multiple images used in post detail
    let imageURL: URL?
    let status: OldPostStatus
    let date: Date
    let location: String
    let category: String
    let reportedBy: OldReporter
 
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        imageName: String,
        images: [String] = [],
        imageURL: URL? = nil,
        status: OldPostStatus,
        date: Date,
        location: String,
        category: String = "General",
        reportedBy: OldReporter = OldReporter(name: "Unknown", avatarName: "")
        
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageName = imageName
        self.images = images.isEmpty ? [imageName] : images
        self.imageURL = imageURL
        self.status = status
        self.date = date
        self.location = location
        self.category = category
        self.reportedBy = reportedBy
    }
}
*/

