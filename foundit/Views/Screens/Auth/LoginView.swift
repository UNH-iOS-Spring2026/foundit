//
//  LoginView.swift
//  foundit
//

import SwiftUI

struct LoginView: View {
	@EnvironmentObject var authVM: AuthViewModel

	@State private var email = ""
	@State private var password = ""
	@State private var showPassword = false

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 0) {
				Spacer().frame(height: 40)

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

				Text("Welcome Back")
					.font(.system(size: 28, weight: .bold))
					.padding(.horizontal, 32)

				Text("Sign in to continue to FoundIt")
					.font(.system(size: 14))
					.foregroundColor(.gray)
					.padding(.horizontal, 32)
					.padding(.top, 4)

				Spacer().frame(height: 22)

				CustomTextField(text: $email, placeholder: "Email")
					.padding(.horizontal, 28)

				Spacer().frame(height: 14)

				CustomSecureField(text: $password, placeholder: "Password", showPassword: $showPassword)
					.padding(.horizontal, 28)

				if !authVM.errorMessage.isEmpty {
					Text(authVM.errorMessage)
						.font(.system(size: 13))
						.foregroundColor(.red)
						.padding(.horizontal, 28)
						.padding(.top, 10)
				}

				Spacer().frame(height: 16)

				Button {
					Task {
						await authVM.login(email: email, password: password)
					}
				} label: {
					HStack {
						Spacer()
						if authVM.isLoading {
							ProgressView()
						} else {
							Text("LOG IN")
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

				Spacer().frame(height: 14)

				HStack {
					line
					Text("or")
						.font(.system(size: 13))
						.foregroundColor(.gray)
					line
				}
				.padding(.horizontal, 28)

				Spacer().frame(height: 14)

				Button {
					Task {
						await authVM.signInWithGoogle()
					}
				} label: {
					HStack(spacing: 12) {
						Spacer()
						Image(systemName: "globe")
							.font(.system(size: 18, weight: .medium))
							.foregroundColor(.black)
						Text("Continue with Google")
							.font(.system(size: 16, weight: .semibold))
							.foregroundColor(.black)
						Spacer()
					}
					.frame(height: 54)
					.background(Color.white)
					.overlay(
						RoundedRectangle(cornerRadius: 14)
							.stroke(Color.gray.opacity(0.3), lineWidth: 1)
					)
					.clipShape(RoundedRectangle(cornerRadius: 14))
				}
				.padding(.horizontal, 28)
				.disabled(authVM.isLoading)

				Spacer().frame(height: 14)

				HStack {
					Spacer()
					NavigationLink(destination: ForgotPasswordView().environmentObject(authVM)) {
						Text("Forgot password?")
							.font(.system(size: 13, weight: .medium))
							.foregroundColor(.red)
					}
					Spacer()
				}

				Spacer().frame(height: 30)

				HStack(spacing: 4) {
					Spacer()
					Text("Don't have an account?")
						.font(.system(size: 14))
						.foregroundColor(.black.opacity(0.75))
					NavigationLink(destination: SignupView().environmentObject(authVM)) {
						Text("Sign up")
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

	private var line: some View {
		Rectangle()
			.fill(Color.gray.opacity(0.25))
			.frame(height: 1)
	}
}
