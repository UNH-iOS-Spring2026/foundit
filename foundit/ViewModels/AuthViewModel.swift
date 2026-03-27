//
//  AuthViewModel.swift
//  foundit
//
//	Source of inspiration for UI: ChatGPT (OpenAI)
//  Created by Ashish Khadka on 26/03/2026.


import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
	@Published var isLoading = false
	@Published var errorMessage = ""
	@Published var resetMessage = ""
	@Published var isAuthenticated = false

	init() {
		isAuthenticated = Auth.auth().currentUser != nil
	}

	func login(email: String, password: String) async {
		errorMessage = ""
		resetMessage = ""

		guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			errorMessage = "Email is required."
			return
		}

		guard !password.isEmpty else {
			errorMessage = "Password is required."
			return
		}

		isLoading = true
		defer { isLoading = false }

		do {
			_ = try await Auth.auth().signIn(withEmail: email, password: password)
			isAuthenticated = true
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	func signup(
		firstName: String,
		lastName: String,
		email: String,
		password: String,
		confirmPassword: String
	) async {
		errorMessage = ""
		resetMessage = ""

		guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			errorMessage = "First name is required."
			return
		}

		guard !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			errorMessage = "Last name is required."
			return
		}

		guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			errorMessage = "Email is required."
			return
		}

		guard password.count >= 6 else {
			errorMessage = "Password must be at least 6 characters."
			return
		}

		guard password == confirmPassword else {
			errorMessage = "Passwords do not match."
			return
		}

		isLoading = true
		defer { isLoading = false }

		do {
			_ = try await Auth.auth().createUser(withEmail: email, password: password)
			isAuthenticated = true
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	func sendReset(email: String) async {
		errorMessage = ""
		resetMessage = ""

		guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			errorMessage = "Email is required."
			return
		}

		isLoading = true
		defer { isLoading = false }

		do {
			try await Auth.auth().sendPasswordReset(withEmail: email)
			resetMessage = "Password reset email sent."
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	func logout() {
		errorMessage = ""
		resetMessage = ""

		do {
			try Auth.auth().signOut()
			isAuthenticated = false
		} catch {
			errorMessage = error.localizedDescription
		}
	}
}
