//
//  RootView.swift
//  foundit
//

import SwiftUI

struct RootView: View {
	@EnvironmentObject var authVM: AuthViewModel
	@AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

	var body: some View {
		Group {
			if authVM.isAuthenticated {
				if authVM.isAdmin {
					PoliceTabView()
				} else {
					MainTabView()
				}
			} else {
				NavigationStack {
					if hasSeenOnboarding {
						LoginView()
					} else {
						SplashView()
					}
				}
			}
		}
		.environmentObject(authVM)
	}
}
