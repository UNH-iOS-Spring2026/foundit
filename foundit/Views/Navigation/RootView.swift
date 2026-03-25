//
//  RootView.swift
//  foundit
//
//  Created by Divya Panthi on 10/03/2026.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        // TODO: Teammate — add auth gating here:
        // if authViewModel.userSession != nil { MainTabView() } else { SplashView() }
        MainTabView()
    }
}

#Preview {
    RootView()
}
