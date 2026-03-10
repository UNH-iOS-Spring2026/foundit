//
//  OnboardingView.swift
//  foundit
//
//  Created by Divya Panthi on 10/03/2026.
//

import SwiftUI

struct OnboardingView: View {
    var body: some View {
         VStack {
             Text("Onboarding Screen")
                 .font(.title)

             NavigationLink("Go to Login", destination: LoginView())
                 .padding()
         }
         .navigationTitle("Onboarding")
     }
}

#Preview {
    OnboardingView()
}
