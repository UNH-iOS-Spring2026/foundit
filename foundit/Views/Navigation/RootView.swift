//
//  RootView.swift
//  foundit
//

import SwiftUI

struct RootView: View {
	@EnvironmentObject var authVM: AuthViewModel

	var body: some View {
		Group {
			if authVM.isAuthenticated {
				if authVM.isAdmin {
					PoliceTabView()
						.environmentObject(authVM)
				} else {
					MainTabView()
						.environmentObject(authVM)
				}
			} else {
				NavigationStack {
					SplashView()
						.environmentObject(authVM)
				}
			}
		}
	}
}
