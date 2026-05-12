//
//  WelcomeView.swift
//  foundit
//

import SwiftUI

struct WelcomeView: View {
    @State private var goToOnboarding = false

    var body: some View {
        ZStack {
            Color(FounditColors.primary)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image("found_it_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)

                Text("Welcome To\nFoundIt")
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .padding(.top, 28)

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
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 60)
                .navigationDestination(isPresented: $goToOnboarding) {
                    OnboardingView()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
