//
//  RootView.swift
//  foundit
//
//  Created by Divya Panthi on 10/03/2026.
//

import SwiftUI

struct RootView: View {
	@StateObject private var authVM = AuthViewModel()

	var body: some View {
		Group {
			if authVM.isAuthenticated {
				MainTabView()
					.environmentObject(authVM)
			} else {
				NavigationStack {
					SplashView()
				}
				.environmentObject(authVM)
			}
		}
	}
}

#Preview {
	RootView()
}
