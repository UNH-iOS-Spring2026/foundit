//
//  ForgotPasswordView.swift
//  foundit
//
//	Source of inspiration for UI: ChatGPT (OpenAI)
//  Created by Ashish Khadka on 3/18/26.
//

import SwiftUI

struct ForgotPasswordView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject var authVM: AuthViewModel

	@State private var email = ""

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 0) {
				Spacer().frame(height: 8)

				HStack {
					Button { dismiss() } label: {
						Image(systemName: "chevron.left")
							.font(.system(size: 16, weight: .medium))
							.foregroundColor(.black)
					}
					Spacer()
				}
				.padding(.horizontal, 24)

				Spacer().frame(height: 30)

				HStack {
					Spacer()
					Image("forgot-password")
						.resizable()
						.scaledToFit()
						.frame(width: 210, height: 210)
					Spacer()
				}

				Spacer().frame(height: 24)

				Text("Forgot Password?")
					.font(.system(size: 28, weight: .bold))
					.frame(maxWidth: .infinity, alignment: .center)

				Text("Please enter your email and we will help you reset your password")
					.font(.system(size: 14))
					.foregroundColor(.black.opacity(0.7))
					.multilineTextAlignment(.center)
					.padding(.horizontal, 40)
					.padding(.top, 8)

				Spacer().frame(height: 28)

				Text("Email Address")
					.font(.system(size: 15))
					.foregroundColor(.gray)
					.padding(.horizontal, 32)
					.padding(.bottom, 8)

				CustomTextField(text: $email, placeholder: "Email Address")
					.padding(.horizontal, 28)

				if !authVM.errorMessage.isEmpty {
					Text(authVM.errorMessage)
						.font(.system(size: 13))
						.foregroundColor(.red)
						.padding(.horizontal, 28)
						.padding(.top, 10)
				}

				if !authVM.resetMessage.isEmpty {
					Text(authVM.resetMessage)
						.font(.system(size: 13))
						.foregroundColor(.green)
						.padding(.horizontal, 28)
						.padding(.top, 10)
				}

				Spacer().frame(height: 22)

				Button {
					Task {
						await authVM.sendReset(email: email)
					}
				} label: {
					HStack {
						Spacer()
						if authVM.isLoading {
							ProgressView()
						} else {
							Text("Reset Password")
								.font(.system(size: 17, weight: .bold))
								.foregroundColor(.black)
						}
						Spacer()
					}
					.frame(height: 54)
					.background(Color(FounditColors.primary))
					.clipShape(RoundedRectangle(cornerRadius: 14))
				}
				.padding(.horizontal, 28)
				.disabled(authVM.isLoading)

				Spacer()
			}
		}
		.background(Color.white.ignoresSafeArea())
		.navigationBarBackButtonHidden(true)
	}
}

#Preview {
	NavigationStack {
		ForgotPasswordView()
			.environmentObject(AuthViewModel())
	}
}
