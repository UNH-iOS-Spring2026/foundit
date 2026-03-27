//
//  RootView.swift
//  foundit
//
//  Created by Divya Panthi on 10/03/2026.
//

import SwiftUI

struct RootView: View {
	@StateObject private var authVM: AuthViewModel = AuthViewModel()

	var body: some View {
		Group {
			if authVM.isAuthenticated {
				Text("Logged In")
					.environmentObject(authVM)
			} else {
				SplashView()
					.environmentObject(authVM)
			}
		}
	}
}

#Preview {
	RootView()
}
