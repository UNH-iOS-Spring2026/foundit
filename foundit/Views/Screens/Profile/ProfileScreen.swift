//
//  ProfileScreen.swift
//  foundit
//
//  Created by Aryan Tandon on 3/24/26.
//

import SwiftUI
import FirebaseAuth
import UserNotifications

struct ProfileScreen: View {
	@EnvironmentObject var authVM: AuthViewModel

	@State private var pushNotificationsEnabled =
        UserDefaults.standard.object(forKey: LocalNotificationManager.enabledPreferenceKey) as? Bool ?? true
	@State private var systemPermissionDenied = false
	@State private var showSettingsAlert = false
	@State private var showLogoutAlert = false
	@State private var toastMessage: String? = nil

	private var userName: String {
		authVM.currentDisplayName.isEmpty ? "User" : authVM.currentDisplayName
	}

	private var userEmail: String {
		authVM.currentUserEmail.isEmpty ? "No email available" : authVM.currentUserEmail
	}

	var body: some View {
		ZStack(alignment: .bottom) {
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
						Image(systemName: systemPermissionDenied ? "bell.slash" : "bell")
							.frame(width: 24)
							.foregroundColor(systemPermissionDenied ? .secondary : .primary)

						VStack(alignment: .leading, spacing: 2) {
							Text("Push Notifications")
								.font(.body)
								.foregroundColor(systemPermissionDenied ? .secondary : .primary)
							if systemPermissionDenied {
								Text("Disabled in Settings")
									.font(.caption)
									.foregroundColor(.secondary)
							}
						}

						Spacer()

						Toggle("", isOn: $pushNotificationsEnabled)
							.labelsHidden()
							.tint(Color(FounditColors.primary))
							.disabled(systemPermissionDenied)
					}
					.padding(.horizontal)
					.padding(.vertical, 14)
					.onTapGesture {
						if systemPermissionDenied {
							showSettingsAlert = true
						}
					}

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
			.onAppear {
				UNUserNotificationCenter.current().getNotificationSettings { settings in
					DispatchQueue.main.async {
						let denied = settings.authorizationStatus == .denied
						systemPermissionDenied = denied
						if denied {
							pushNotificationsEnabled = false
						} else {
							pushNotificationsEnabled = UserDefaults.standard.object(
								forKey: LocalNotificationManager.enabledPreferenceKey
							) as? Bool ?? true
						}
					}
				}
			}
			.onChange(of: pushNotificationsEnabled) { _, newValue in
				if newValue, systemPermissionDenied {
					pushNotificationsEnabled = false
					showSettingsAlert = true
					return
				}
				UserDefaults.standard.set(newValue, forKey: LocalNotificationManager.enabledPreferenceKey)
				showToast(newValue ? "Notifications enabled" : "Notifications disabled")
			}
			.alert("Notifications Disabled", isPresented: $showSettingsAlert) {
				Button("Open Settings") {
					if let url = URL(string: UIApplication.openSettingsURLString) {
						UIApplication.shared.open(url)
					}
				}
				Button("Cancel", role: .cancel) { }
			} message: {
				Text("Notifications are disabled for foundit. Go to Settings to enable them.")
			}
			.alert("Logout", isPresented: $showLogoutAlert) {
				Button("Cancel", role: .cancel) { }

				Button("Logout", role: .destructive) {
					authVM.signOut()
				}
			} message: {
				Text("Are you sure you want to log out?")
			}
		}

		// Toast card
		if toastMessage != nil {
			HStack(spacing: 14) {
				ZStack {
					Circle()
						.fill(.white.opacity(0.2))
						.frame(width: 44, height: 44)
					Image(systemName: pushNotificationsEnabled ? "bell.fill" : "bell.slash.fill")
						.font(.system(size: 20, weight: .semibold))
						.foregroundStyle(.white)
				}

				VStack(alignment: .leading, spacing: 3) {
					Text(pushNotificationsEnabled ? "Notifications On" : "Notifications Off")
						.font(.system(size: 15, weight: .semibold))
						.foregroundStyle(.white)
					Text(pushNotificationsEnabled
						 ? "You'll receive alerts for new matches"
						 : "Banner alerts are paused")
						.font(.system(size: 13))
						.foregroundStyle(.white.opacity(0.85))
				}

				Spacer()
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 14)
			.background(
				pushNotificationsEnabled
					? Color(FounditColors.primary)
					: Color(.systemGray2),
				in: RoundedRectangle(cornerRadius: 16)
			)
			.shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
			.padding(.horizontal, 16)
			.padding(.bottom, 20)
			.transition(.move(edge: .bottom).combined(with: .opacity))
			.zIndex(1)
		}
		} // ZStack
		.animation(.spring(duration: 0.4), value: toastMessage)
	}

	private func showToast(_ message: String) {
		toastMessage = message
		Task {
			try? await Task.sleep(for: .seconds(2))
			toastMessage = nil
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
