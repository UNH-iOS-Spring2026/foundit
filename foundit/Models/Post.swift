//
//  Post.swift
//  foundit
//
//  Written by Rohan Poudel, assisted by Claude.
//
//  The user-facing record of a lost or found report. This is what the
//  home feed, search, and post detail screens are built around. The
//  matching physical-custody record lives in `Item.swift`.
//

import Foundation
import FirebaseFirestore

/// Whether the post is someone reporting a lost item or a found item.
/// Drives the badge color and the matching logic on the backend.
enum PostType: String, Codable {
    case lost
    case found

    var label: String {
        switch self {
        case .lost:  return "Lost"
        case .found: return "Found"
        }
    }
}

/// Lifecycle of a post. `returned` is set by the QR claim flow once the
/// item physically reaches the owner.
enum PostStatus: String, Codable {
    case open
    case matched
    case waitingForPickup
    case returned
}

// MARK: - Reporter Info

/// Display-only snapshot of the person who created the post.
/// Embedded inside the Post document so the feed can render the row
/// without fetching the full user profile.
struct Reporter: Codable, Hashable {
    var name: String
    var avatarUrl: String?  // URL to avatar image in Firebase Storage
    
    init(name: String = "Unknown", avatarUrl: String? = nil) {
        self.name = name
        self.avatarUrl = avatarUrl
    }
}

// MARK: - Main Post Model

/// One lost or found report. Lives in the top-level `posts` collection
/// and is the source of truth for the feed, search, and detail screens.
struct Post: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var type: PostType
    var title: String
    var description: String
    /// Free-form category label ("Electronics", "Books", etc.).
    var category: String
    /// Firebase Storage URLs for the uploaded photos. First entry is the cover.
    var photoUrls: [String]
    /// Geo-coordinate where the item was last seen / found.
    var lastSeenLocation: GeoPoint
    /// Human-readable version of the location ("Maxcy Hall", "Bergami").
    var lastSeenLocationText: String
    var status: PostStatus
    /// UID of the user who created the post.
    var createdBy: String
    /// Embedded snapshot of the reporter for inbox/feed display.
    var reporterInfo: Reporter?
    var mobileNumber: String?
    /// When true the UI hides the phone number even if it exists.
    var hideContactDetails: Bool
    var createdAt: Timestamp
    var updatedAt: Timestamp
    
    // Custom decoding path. We need this because @DocumentID can't coexist
    // with a synthesized init and because older docs may be missing optional
    // fields like `photoUrls` and `hideContactDetails` — those are defaulted
    // instead of failing the whole decode.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // @DocumentID doesn't work with custom init, so we handle id separately
        id = try container.decodeIfPresent(String.self, forKey: .id)
        type = try container.decode(PostType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(String.self, forKey: .category)
        
        // Provide default empty array if photoUrls is missing
        photoUrls = try container.decodeIfPresent([String].self, forKey: .photoUrls) ?? []
        
        lastSeenLocation = try container.decode(GeoPoint.self, forKey: .lastSeenLocation)
        lastSeenLocationText = try container.decode(String.self, forKey: .lastSeenLocationText)
        status = try container.decode(PostStatus.self, forKey: .status)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        reporterInfo = try container.decodeIfPresent(Reporter.self, forKey: .reporterInfo)
        mobileNumber = try container.decodeIfPresent(String.self, forKey: .mobileNumber)
        hideContactDetails = try container.decodeIfPresent(Bool.self, forKey: .hideContactDetails) ?? false
        createdAt = try container.decode(Timestamp.self, forKey: .createdAt)
        updatedAt = try container.decode(Timestamp.self, forKey: .updatedAt)
    }
    
    // Convenience initializer used when constructing posts in code
    // (mock data, post-creation flow, tests).
    init(
        id: String? = nil,
        type: PostType,
        title: String,
        description: String,
        category: String,
        photoUrls: [String],
        lastSeenLocation: GeoPoint,
        lastSeenLocationText: String,
        status: PostStatus,
        createdBy: String,
        reporterInfo: Reporter? = nil,
        mobileNumber: String? = nil,
        hideContactDetails: Bool = false,
        createdAt: Timestamp,
        updatedAt: Timestamp
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.category = category
        self.photoUrls = photoUrls
        self.lastSeenLocation = lastSeenLocation
        self.lastSeenLocationText = lastSeenLocationText
        self.status = status
        self.createdBy = createdBy
        self.reporterInfo = reporterInfo
        self.mobileNumber = mobileNumber
        self.hideContactDetails = hideContactDetails
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case description
        case category
        case photoUrls
        case lastSeenLocation
        case lastSeenLocationText
        case status
        case createdBy
        case reporterInfo
        case mobileNumber
        case hideContactDetails
        case createdAt
        case updatedAt
    }
}
// MARK: - Computed Properties
extension Post {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: createdAt.dateValue())
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: createdAt.dateValue())
    }
    
    var coordinate: ItemCoordinate {
        ItemCoordinate(
            latitude: lastSeenLocation.latitude,
            longitude: lastSeenLocation.longitude
        )
    }
    
    // Primary image URL
    var primaryImageUrl: String? {
        photoUrls.first
    }
}

// MARK: - Helper Types

/// Plain coordinate pair used by the map UI — decoupled from Firestore's
/// GeoPoint so SwiftUI views don't need to import FirebaseFirestore.
struct ItemCoordinate {
    let latitude: Double
    let longitude: Double
}

// MARK: - Mock Data for Testing

/// Static sample posts used by SwiftUI previews and offline UI work.
extension Post {
    static let mockItems: [Post] = [
        Post(
            id: UUID().uuidString,
            type: .lost,
            title: "TOri",
            description: "White Apple USB-C charger with cable.",
            category: "Electronics",
            photoUrls: ["charger"],
            lastSeenLocation: GeoPoint(latitude: 41.3083, longitude: -72.9279),
            lastSeenLocationText: "Maxcy Hall",
            status: .open,
            createdBy: "user123",
            reporterInfo: Reporter(name: "Divya", avatarUrl: "profile"),
            createdAt: Timestamp(date: DateComponents(calendar: .current, year: 2026, month: 1, day: 11).date ?? Date()),
            updatedAt: Timestamp(date: Date())
        ),
        Post(
            id: UUID().uuidString,
            type: .found,
            title: "Black Earphones",
            description: "Black wireless earbuds with charging case.",
            category: "Electronics",
            photoUrls: ["earphones"],
            lastSeenLocation: GeoPoint(latitude: 41.3075, longitude: -72.9285),
            lastSeenLocationText: "Bergami",
            status: .open,
            createdBy: "user456",
            createdAt: Timestamp(date: DateComponents(calendar: .current, year: 2026, month: 1, day: 25).date ?? Date()),
            updatedAt: Timestamp(date: Date())
        ),
        Post(
            id: UUID().uuidString,
            type: .found,
            title: "Red Book",
            description: "Red hardcover book, no title on cover.",
            category: "Books",
            photoUrls: ["book"],
            lastSeenLocation: GeoPoint(latitude: 41.3083, longitude: -72.9279),
            lastSeenLocationText: "UNH Campus",
            status: .open,
            createdBy: "user789",
            createdAt: Timestamp(date: DateComponents(calendar: .current, year: 2026, month: 1, day: 22).date ?? Date()),
            updatedAt: Timestamp(date: Date())
        ),
        Post(
            id: UUID().uuidString,
            type: .lost,
            title: "Black Eye Glasses",
            description: "Black cat-eye prescription glasses.",
            category: "Accessories",
            photoUrls: ["glasses"],
            lastSeenLocation: GeoPoint(latitude: 41.3090, longitude: -72.9290),
            lastSeenLocationText: "Bethel",
            status: .open,
            createdBy: "user101",
            reporterInfo: Reporter(name: "John Doe"),
            createdAt: Timestamp(date: DateComponents(calendar: .current, year: 2026, month: 1, day: 31).date ?? Date()),
            updatedAt: Timestamp(date: Date())
        )
    ]
}

