//
//  SignupView.swift
//  foundit
//
//	Source of inspiration for UI: ChatGPT (OpenAI)
//  Created by Ashish Khadka on 18/03/2026.
//

import SwiftUI

struct SignupView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject var authVM: AuthViewModel

	@State private var firstName = ""
	@State private var lastName = ""
	@State private var email = ""
	@State private var password = ""
	@State private var confirmPassword = ""
	@State private var showPassword = false
	@State private var showConfirmPassword = false

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

				Spacer().frame(height: 28)

				HStack(spacing: 12) {
					Image("logo-blue")
						.resizable()
						.scaledToFit()
						.frame(width: 42, height: 42)

					Text("FoundIt")
						.font(.system(size: 24, weight: .bold))
						.foregroundColor(.black)
				}
				.padding(.horizontal, 32)

				Spacer().frame(height: 38)

				Text("Create Account")
					.font(.system(size: 28, weight: .bold))
					.padding(.horizontal, 32)

				Text("Create your account to start using FoundIt")
					.font(.system(size: 14))
					.foregroundColor(.gray)
					.padding(.horizontal, 32)
					.padding(.top, 4)

				Spacer().frame(height: 22)

				CustomTextField(text: $firstName, placeholder: "First name")
					.padding(.horizontal, 28)
				Spacer().frame(height: 14)

				CustomTextField(text: $lastName, placeholder: "Last name")
					.padding(.horizontal, 28)
				Spacer().frame(height: 14)

				CustomTextField(text: $email, placeholder: "Email")
					.padding(.horizontal, 28)
				Spacer().frame(height: 14)

				CustomSecureField(text: $password, placeholder: "Password", showPassword: $showPassword)
					.padding(.horizontal, 28)
				Spacer().frame(height: 14)

				CustomSecureField(text: $confirmPassword, placeholder: "Confirm Password", showPassword: $showConfirmPassword)
					.padding(.horizontal, 28)

				if !authVM.errorMessage.isEmpty {
					Text(authVM.errorMessage)
						.font(.system(size: 13))
						.foregroundColor(.red)
						.padding(.horizontal, 28)
						.padding(.top, 10)
				}

				Spacer().frame(height: 18)

				Button {
					Task {
						await authVM.signup(
							firstName: firstName,
							lastName: lastName,
							email: email,
							password: password,
							confirmPassword: confirmPassword
						)
					}
				} label: {
					HStack {
						Spacer()
						if authVM.isLoading {
							ProgressView()
						} else {
							Text("SIGN UP")
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

				Spacer().frame(height: 20)

				HStack(spacing: 4) {
					Spacer()
					Text("Already have an account?")
						.font(.system(size: 14))
						.foregroundColor(.black.opacity(0.75))
					NavigationLink(destination: LoginView().environmentObject(authVM)) {
						Text("Login")
							.font(.system(size: 14, weight: .medium))
							.foregroundColor(.blue)
					}
					Spacer()
				}

				Spacer().frame(height: 30)
			}
		}
		.background(Color.white.ignoresSafeArea())
		.navigationBarBackButtonHidden(true)
	}
}

#Preview {
	NavigationStack {
		SignupView()
			.environmentObject(AuthViewModel())
	}
}
