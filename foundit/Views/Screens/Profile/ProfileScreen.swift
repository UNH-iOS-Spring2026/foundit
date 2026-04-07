//
//  ProfileScreen.swift
//  foundit
//
//  Created by Aryan Tandon on 3/24/26.
//

import SwiftUI
import FirebaseAuth

struct ProfileScreen: View {
	@EnvironmentObject var authVM: AuthViewModel

	@State private var pushNotificationsEnabled = true
	@State private var showLogoutAlert = false

	private var userName: String {
		authVM.currentDisplayName.isEmpty ? "User" : authVM.currentDisplayName
	}

	private var userEmail: String {
		authVM.currentUserEmail.isEmpty ? "No email available" : authVM.currentUserEmail
	}

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				VStack(spacing: 8) {
					Image(systemName: "person.circle.fill")
						.resizable()
						.frame(width: 80, height: 80)
						.foregroundColor(.gray)

					Text(userName)
						.font(.title2)
						.fontWeight(.semibold)

					Text(userEmail)
						.font(.subheadline)
						.foregroundColor(.secondary)
				}
				.padding(.vertical, 24)

				Divider()

				VStack(spacing: 0) {
					ProfileMenuItem(icon: "globe", title: "My post") { MyPostsView() }
					ProfileMenuItem(icon: "square.and.pencil", title: "Edit Profile") {
						EditProfileView()
					}
					if !authVM.isGoogleUser {
						ProfileMenuItem(icon: "lock", title: "Change Password") {
							ChangePasswordView()
						}
					}

					HStack {
						Image(systemName: "bell")
							.frame(width: 24)
							.foregroundColor(.primary)

						Text("Push Notifications")
							.font(.body)

						Spacer()

						Toggle("", isOn: $pushNotificationsEnabled)
							.labelsHidden()
					}
					.padding(.horizontal)
					.padding(.vertical, 14)

					Button {
						showLogoutAlert = true
					} label: {
						HStack {
							Image(systemName: "rectangle.portrait.and.arrow.right")
								.frame(width: 24)

							Text("Logout")
								.font(.body)

							Spacer()
						}
						.foregroundColor(.primary)
						.padding(.horizontal)
						.padding(.vertical, 14)
					}
				}

				Spacer()
			}
			.navigationTitle("Profile")
			.navigationBarTitleDisplayMode(.inline)
			.alert("Logout", isPresented: $showLogoutAlert) {
				Button("Cancel", role: .cancel) { }

				Button("Logout", role: .destructive) {
					authVM.signOut()
				}
			} message: {
				Text("Are you sure you want to log out?")
			}
		}
	}
}

struct ProfileMenuItem<Destination: View>: View {
	let icon: String
	let title: String
	@ViewBuilder let destination: () -> Destination

	var body: some View {
		NavigationLink(destination: destination()) {
			HStack {
				Image(systemName: icon)
					.frame(width: 24)
					.foregroundColor(.primary)

				Text(title)
					.font(.body)
					.foregroundColor(.primary)

				Spacer()

				Image(systemName: "chevron.right")
					.font(.caption)
					.foregroundColor(.secondary)
			}
			.padding(.horizontal)
			.padding(.vertical, 14)
		}
	}
}

#Preview {
	NavigationStack {
		ProfileScreen()
			.environmentObject(AuthViewModel())
	}
}
