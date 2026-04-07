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
				MainTabView()
					.environmentObject(authVM)
			} else {
				NavigationStack {
					SplashView()
						.environmentObject(authVM)
				}
			}
		}
	}
}
