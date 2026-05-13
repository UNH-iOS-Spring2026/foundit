//
//  SplashView.swift
//  foundit
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(FounditColors.primary)
                .ignoresSafeArea()

            Image("found_it_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
        }
    }
}

#Preview {
    SplashView()
}
