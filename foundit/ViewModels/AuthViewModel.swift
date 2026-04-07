//
//  AuthViewModel.swift
//  foundit
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn
import UIKit

@MainActor
final class AuthViewModel: ObservableObject {
	@Published var isAuthenticated = false
	@Published var isLoading = false
	@Published var errorMessage = ""
	@Published var resetMessage = ""
	@Published var currentUserEmail = ""

	private let db = Firestore.firestore()
	private var authStateHandle: AuthStateDidChangeListenerHandle?

	var currentUser: FirebaseAuth.User? {
		Auth.auth().currentUser
	}
	
	func logout() {
		signOut()
	}

	init() {
		if let user = Auth.auth().currentUser {
			isAuthenticated = true
			currentUserEmail = user.email ?? ""
		} else {
			isAuthenticated = false
			currentUserEmail = ""
		}

		authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
			guard let self else { return }
			Task { @MainActor in
				self.isAuthenticated = (user != nil)
				self.currentUserEmail = user?.email ?? ""
			}
		}
	}

	deinit {
		if let authStateHandle {
			Auth.auth().removeStateDidChangeListener(authStateHandle)
		}
	}

	// MARK: - Login
	func login(email: String, password: String) async {
		errorMessage = ""
		resetMessage = ""

		let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
		let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

		guard !cleanEmail.isEmpty, !cleanPassword.isEmpty else {
			errorMessage = "Please enter email and password."
			return
		}

		isLoading = true
		defer { isLoading = false }

		do {
			let result = try await Auth.auth().signIn(withEmail: cleanEmail, password: cleanPassword)
			currentUserEmail = result.user.email ?? ""

			await createOrUpdateUserDocument(
				uid: result.user.uid,
				firstName: nil,
				lastName: nil,
				email: result.user.email,
				fallbackDisplayName: result.user.displayName
			)

			isAuthenticated = true
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	// MARK: - Signup
	func signup(
		firstName: String,
		lastName: String,
		email: String,
		password: String,
		confirmPassword: String
	) async {
		errorMessage = ""
		resetMessage = ""

		let cleanFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
		let cleanLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
		let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
		let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
		let cleanConfirmPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

		guard !cleanFirstName.isEmpty,
			  !cleanLastName.isEmpty,
			  !cleanEmail.isEmpty,
			  !cleanPassword.isEmpty,
			  !cleanConfirmPassword.isEmpty else {
			errorMessage = "Please fill in all fields."
			return
		}

		guard cleanPassword == cleanConfirmPassword else {
			errorMessage = "Passwords do not match."
			return
		}

		guard cleanPassword.count >= 6 else {
			errorMessage = "Password must be at least 6 characters."
			return
		}

		isLoading = true
		defer { isLoading = false }

		do {
			let result = try await Auth.auth().createUser(withEmail: cleanEmail, password: cleanPassword)

			let fullName = "\(cleanFirstName) \(cleanLastName)".trimmingCharacters(in: .whitespaces)

			let changeRequest = result.user.createProfileChangeRequest()
			changeRequest.displayName = fullName
			try await changeRequest.commitChanges()

			await createOrUpdateUserDocument(
				uid: result.user.uid,
				firstName: cleanFirstName,
				lastName: cleanLastName,
				email: cleanEmail,
				fallbackDisplayName: fullName
			)

			currentUserEmail = cleanEmail
			isAuthenticated = true
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	// MARK: - Forgot Password
	func sendReset(email: String) async {
		errorMessage = ""
		resetMessage = ""

		let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

		guard !cleanEmail.isEmpty else {
			errorMessage = "Please enter your email."
			return
		}

		isLoading = true
		defer { isLoading = false }

		do {
			try await Auth.auth().sendPasswordReset(withEmail: cleanEmail)
			resetMessage = "Password reset email sent."
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	// MARK: - Google Sign In
	func signInWithGoogle() async {
		errorMessage = ""
		resetMessage = ""

		guard let clientID = FirebaseApp.app()?.options.clientID else {
			errorMessage = "Missing Firebase client ID."
			return
		}

		guard let rootViewController = UIApplication.shared.topViewController() else {
			errorMessage = "Could not access screen for Google Sign-In."
			return
		}

		isLoading = true
		defer { isLoading = false }

		do {
			let config = GIDConfiguration(clientID: clientID)
			GIDSignIn.sharedInstance.configuration = config

			let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

			guard let idToken = result.user.idToken?.tokenString else {
				errorMessage = "Google ID token not found."
				return
			}

			let accessToken = result.user.accessToken.tokenString
			let credential = GoogleAuthProvider.credential(
				withIDToken: idToken,
				accessToken: accessToken
			)

			let authResult = try await Auth.auth().signIn(with: credential)
			let firebaseUser = authResult.user

			let email = firebaseUser.email ?? result.user.profile?.email
			let displayName = firebaseUser.displayName ?? result.user.profile?.name

			await createOrUpdateUserDocument(
				uid: firebaseUser.uid,
				firstName: nil,
				lastName: nil,
				email: email,
				fallbackDisplayName: displayName
			)

			currentUserEmail = email ?? ""
			isAuthenticated = true
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	// MARK: - Logout
	func signOut() {
		errorMessage = ""
		resetMessage = ""

		do {
			try Auth.auth().signOut()
			GIDSignIn.sharedInstance.signOut()
			currentUserEmail = ""
			isAuthenticated = false
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	// MARK: - Firestore
	private func createOrUpdateUserDocument(
		uid: String,
		firstName: String?,
		lastName: String?,
		email: String?,
		fallbackDisplayName: String?
	) async {
		let trimmedFirst = firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		let trimmedLast = lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

		let combinedName = "\(trimmedFirst) \(trimmedLast)".trimmingCharacters(in: .whitespacesAndNewlines)

		let finalDisplayName: String
		if !combinedName.isEmpty {
			finalDisplayName = combinedName
		} else if let fallbackDisplayName, !fallbackDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			finalDisplayName = fallbackDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
		} else if let email, !email.isEmpty {
			finalDisplayName = email.components(separatedBy: "@").first ?? "User"
		} else {
			finalDisplayName = "User"
		}

		let userRef = db.collection("users").document(uid)

		do {
			let snapshot = try await userRef.getDocument()

			if snapshot.exists {
				try await userRef.setData([
					"displayName": finalDisplayName,
					"email": email ?? "",
					"updatedAt": FieldValue.serverTimestamp()
				], merge: true)
			} else {
				try await userRef.setData([
					"displayName": finalDisplayName,
					"email": email ?? "",
					"isAdmin": false,
					"createdAt": FieldValue.serverTimestamp(),
					"updatedAt": FieldValue.serverTimestamp()
				], merge: true)
			}
		} catch {
			errorMessage = error.localizedDescription
		}
	}
}
