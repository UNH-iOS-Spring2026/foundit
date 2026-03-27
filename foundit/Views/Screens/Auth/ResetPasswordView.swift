//
//  ResetPasswordView.swift
//  foundit
//
//	Source of inspiration for UI: ChatGPT (OpenAI)
//  Created by Ashish Khadka on 18/03/2026.
//

import SwiftUI

struct ResetPasswordView: View {
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		VStack(spacing: 20) {
			Spacer().frame(height: 40)

			Text("Password Reset")
				.font(.system(size: 30, weight: .bold))

			Text("Check your email for the password reset link.")
				.font(.system(size: 15))
				.foregroundColor(.black.opacity(0.7))
				.multilineTextAlignment(.center)
				.padding(.horizontal, 32)

			Button {
				dismiss()
			} label: {
				Text("Back")
					.font(.system(size: 17, weight: .bold))
					.foregroundColor(.black)
					.frame(maxWidth: .infinity)
					.frame(height: 54)
					.background(Color(FounditColors.primary))
					.clipShape(RoundedRectangle(cornerRadius: 14))
			}
			.padding(.horizontal, 28)

			Spacer()
		}
		.background(Color.white.ignoresSafeArea())
		.navigationBarBackButtonHidden(true)
	}
}

#Preview {
	NavigationStack {
		ResetPasswordView()
	}
}
