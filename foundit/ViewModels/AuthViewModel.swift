//
//  AuthViewModel.swift
//  foundit
//
//	Source of inspiration for UI: ChatGPT (OpenAI)
//  Created by Ashish Khadka on 26/03/2026.


import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthViewModel: ObservableObject {
	@Published var isLoading = false
	@Published var errorMessage = ""
	@Published var resetMessage = ""
	@Published var isAuthenticated = false
	@Published var currentUser: User?

	private var authStateListener: AuthStateDidChangeListenerHandle?

	var currentUserId: String {
		Auth.auth().currentUser?.uid ?? ""
	}

	init() {
		isAuthenticated = Auth.auth().currentUser != nil
		authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
			Task { @MainActor in
				self?.isAuthenticated = user != nil
				if let user = user {
					await self?.fetchUser(uid: user.uid)
				} else {
					self?.currentUser = nil
				}
			}
		}
		if let uid = Auth.auth().currentUser?.uid {
			Task { await fetchUser(uid: uid) }
		}
	}

	deinit {
		if let handle = authStateListener {
			Auth.auth().removeStateDidChangeListener(handle)
		}
	}

	private func fetchUser(uid: String) async {
		do {
			let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
			if snapshot.exists {
				self.currentUser = try snapshot.data(as: User.self)
			}
		} catch {
			print("Error fetching user: \(error.localizedDescription)")
		}
	}

	private func createUserDocument(uid: String, displayName: String, email: String) async {
		let now = Timestamp()
		let user = User(
			id: uid,
			displayName: displayName,
			email: email,
			isAdmin: false,
			createdAt: now,
			updatedAt: now
		)
		do {
			try Firestore.firestore().collection("users").document(uid).setData(from: user)
			self.currentUser = user
		} catch {
			print("Error creating user document: \(error.localizedDescription)")
		}
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
			let result = try await Auth.auth().createUser(withEmail: email, password: password)
			let displayName = "\(firstName.trimmingCharacters(in: .whitespacesAndNewlines)) \(lastName.trimmingCharacters(in: .whitespacesAndNewlines))"
			await createUserDocument(uid: result.user.uid, displayName: displayName, email: email)
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
