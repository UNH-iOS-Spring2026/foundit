//
//  RootView.swift
//  foundit
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // Splash only shows for returning users (hasSeenOnboarding already true at launch)
    @State private var showSplash: Bool

    init() {
        let hasSeen = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        _showSplash = State(initialValue: hasSeen)
    }

    var body: some View {
        Group {
            if showSplash || (hasSeenOnboarding && authVM.isAuthLoading) {
                SplashView()
            } else if authVM.isAuthenticated {
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
                        WelcomeView()
                    }
                }
            }
        }
        .environmentObject(authVM)
        .task {
            guard showSplash else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1.0 seconds
            showSplash = false
        }
    }
}
