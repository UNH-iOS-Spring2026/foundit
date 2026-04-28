//
//  AppDelegate.swift
//  foundit
//
//  Created by Ashish Khadka on 4/1/26.
//

import UIKit
import FirebaseCore
import GoogleSignIn
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
	) -> Bool {
		FirebaseApp.configure()
		
		// Request notification permissions
		requestNotificationPermissions(application: application)
		
		return true
	}
	
	private func requestNotificationPermissions(application: UIApplication) {
		let center = UNUserNotificationCenter.current()
		center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
			if let error = error {
				print("Error requesting notification permissions: \(error.localizedDescription)")
				return
			}
			
			if granted {
				print("Notification permissions granted")
				DispatchQueue.main.async {
					application.registerForRemoteNotifications()
				}
			} else {
				print("Notification permissions denied")
			}
		}
	}

	func application(
		_ app: UIApplication,
		open url: URL,
		options: [UIApplication.OpenURLOptionsKey : Any] = [:]
	) -> Bool {
		return GIDSignIn.sharedInstance.handle(url)
	}
}
