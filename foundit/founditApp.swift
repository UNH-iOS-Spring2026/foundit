//
//  founditApp.swift
//  foundit
//
//  Created by Rohan Poudel on 3/9/26.
//

import SwiftUI
import FirebaseCore

@main
struct founditApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
