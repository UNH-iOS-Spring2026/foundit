//
//  SplashView.swift
//  foundit
//
//  Created by Divya Panthi on 10/03/2026.
//

import SwiftUI

struct SplashView: View {
    @State private var goToOnboarding = false
    var body: some View {
        ZStack {
            Color(FounditColors.primary)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 180)

                Image("logo-white")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170, height: 170)

                Text("Welcome To\nFoundIt")
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .padding(.top, 24)

                Spacer()

                Button {
                    goToOnboarding = true
                } label: {
                    Text("GET STARTED")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 60)
                NavigationLink("", destination: OnboardingView(), isActive: $goToOnboarding)
                                    .hidden()
            }
        }.navigationBarBackButtonHidden(true)

    }
    
}

#Preview {
    SplashView()
}
