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

	private var userEmail: String {
		Auth.auth().currentUser?.email ?? "No email available"
	}

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				VStack(spacing: 8) {
					Image(systemName: "person.circle.fill")
						.resizable()
						.frame(width: 80, height: 80)
						.foregroundColor(.gray)

					Text("Dev User")
						.font(.title2)
						.fontWeight(.semibold)

					Text(userEmail)
						.font(.subheadline)
						.foregroundColor(.secondary)
				}
				.padding(.vertical, 24)

				Divider()

				VStack(spacing: 0) {
					ProfileMenuItem(icon: "globe", title: "My post")
					ProfileMenuItem(icon: "square.and.pencil", title: "Edit Profile")
					ProfileMenuItem(icon: "lock", title: "Change Password")

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

					Button(action: {
						showLogoutAlert = true
					}) {
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
				Button("Cancel", role: .cancel) {}

				Button("Logout", role: .destructive) {
					authVM.logout()
				}
			} message: {
				Text("Are you sure you want to log out?")
			}
		}
	}
}

struct ProfileMenuItem: View {
	let icon: String
	let title: String

	var body: some View {
		NavigationLink(destination: EmptyView()) {
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
	}
	.environmentObject(AuthViewModel())
}
