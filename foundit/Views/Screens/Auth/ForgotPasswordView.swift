//
//  ForgotPasswordView.swift
//  foundit
//
//  Created by Ashish Khadka on 3/18/26.
//

import SwiftUI

struct ForgotPasswordView: View {
	@State private var email = ""

	var body: some View {
		VStack(spacing: 20) {
			Text("Forgot Password")
				.font(.title)

			TextField("Email Address", text: $email)
				.padding()
				.background(Color(.systemGray6))
				.cornerRadius(10)
				.padding(.horizontal)

			NavigationLink("Reset Password", destination: ResetPasswordView())
				.padding()
		}
		.navigationTitle("Forgot Password")
	}
}

#Preview {
	NavigationStack {
		ForgotPasswordView()
	}
}
