//
//  AppConfig.swift
//  foundit
//

import Foundation
import FirebaseAuth

struct AppConfig {
    static var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    /// Deprecated: Use currentUserId instead.
    static var placeholderUserId: String {
        currentUserId
    }
}
