//
//  founditApp.swift
//  foundit
//

import SwiftUI
import FirebaseCore

@main
struct founditApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
	@StateObject private var authVM = AuthViewModel()

	var body: some Scene {
		WindowGroup {
			RootView()
				.environmentObject(authVM)
		}
	}
}
