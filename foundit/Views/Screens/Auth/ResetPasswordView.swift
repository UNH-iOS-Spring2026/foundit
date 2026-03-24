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

	@State private var newPassword = "************"
	@State private var confirmPassword = "************"
	@State private var showNewPassword = false
	@State private var showConfirmPassword = false

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 0) {
				Spacer().frame(height: 8)

				HStack {
					Button {
						dismiss()
					} label: {
						Image(systemName: "chevron.left")
							.font(.system(size: 16, weight: .medium))
							.foregroundColor(.black)
					}

					Spacer()
				}
				.padding(.horizontal, 24)

				Spacer().frame(height: 40)

				Text("Create new password")
					.font(.system(size: 30, weight: .bold))
					.foregroundColor(.black)
					.padding(.horizontal, 32)

				Text("Set a strong password to secure your account.")
					.font(.system(size: 14))
					.foregroundColor(.black.opacity(0.7))
					.padding(.horizontal, 32)
					.padding(.top, 8)

				Spacer().frame(height: 34)

				Text("New Password")
					.font(.system(size: 15))
					.foregroundColor(.gray)
					.padding(.horizontal, 32)
					.padding(.bottom, 8)

				CustomSecureField(
					text: $newPassword,
					placeholder: "New Password",
					showPassword: $showNewPassword
				)
				.padding(.horizontal, 28)

				Spacer().frame(height: 18)

				Text("Confirm New Password")
					.font(.system(size: 15))
					.foregroundColor(.gray)
					.padding(.horizontal, 32)
					.padding(.bottom, 8)

				CustomSecureField(
					text: $confirmPassword,
					placeholder: "Confirm New Password",
					showPassword: $showConfirmPassword
				)
				.padding(.horizontal, 28)

				Spacer().frame(height: 24)

				Button(action: {}) {
					Text("Submit")
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
