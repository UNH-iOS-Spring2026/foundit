//
//  LostFoundItem.swift
//  foundit
//
//  Created by Divya Panthi on 17/03/2026.
//

import Foundation
import UIKit

enum ItemStatus {
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
struct Reporter: Identifiable {
    let id: UUID
    let name: String
    let avatarName: String        // Asset catalog image name
 
    init(id: UUID = UUID(), name: String, avatarName: String) {
        self.id = id
        self.name = name
        self.avatarName = avatarName
    }
}

struct ItemCoordinate {
    let latitude: Double
    let longitude: Double
}

struct LostFoundItem: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let imageName: String
    let images: [String]  // multiple images used in post detail
    let imageURL: URL?
    let status: ItemStatus
    let date: Date
    let location: String
 
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        imageName: String,
        images: [String] = [],
        imageURL: URL? = nil,
        status: ItemStatus,
        date: Date,
        location: String
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
    }
}

extension LostFoundItem {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}


extension LostFoundItem {
    static let mockItems: [LostFoundItem] = [
        LostFoundItem(
            title: "iPhone Charger",
            description: "White Apple USB-C charger with cable.",
            imageName: "charger",
            status: .lost,
            date: DateComponents(calendar: .current, year: 2026, month: 1, day: 11).date ?? Date(),
            location: "Maxcy Hall"
        ),
        LostFoundItem(
            title: "Black Earphones",
            description: "Black wireless earbuds with charging case.",
            imageName: "charger",
            status: .found,
            date: DateComponents(calendar: .current, year: 2026, month: 1, day: 25).date ?? Date(),
            location: "Bergami"
        ),
        LostFoundItem(
            title: "Red Book",
            description: "Red hardcover book, no title on cover.",
            imageName: "charger",
            status: .found,
            date: DateComponents(calendar: .current, year: 2026, month: 1, day: 22).date ?? Date(),
            location: "UNH Campus"
        ),
        LostFoundItem(
            title: "Black Eye Glasses",
            description: "Black cat-eye prescription glasses.",
            imageName: "charger",
            status: .lost,
            date: DateComponents(calendar: .current, year: 2026, month: 1, day: 31).date ?? Date(),
            location: "Bethel"
        ),
        LostFoundItem(
            title: "Black Eye Glasses",
            description: "Black cat-eye prescription glasses.",
            imageName: "charger",
            status: .lost,
            date: DateComponents(calendar: .current, year: 2026, month: 1, day: 31).date ?? Date(),
            location: "Bethel"
        ),
        LostFoundItem(
            title: "Black Eye Glasses",
            description: "Black cat-eye prescription glasses.",
            imageName: "charger",
            status: .lost,
            date: DateComponents(calendar: .current, year: 2026, month: 1, day: 31).date ?? Date(),
            location: "Bethel"
        )
    ]
}
