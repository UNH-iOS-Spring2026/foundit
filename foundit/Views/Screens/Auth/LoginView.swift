//
//  LoginView.swift
//  foundit
//
//  Created by Divya Panthi on 10/03/2026.
//

import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack {
            Text("Login Screen")
                .font(.title)

            NavigationLink("Go to Home", destination: HomeView())
                .padding()
        }
        .navigationTitle("Login")
    }
}

#Preview {
    LoginView()
}
