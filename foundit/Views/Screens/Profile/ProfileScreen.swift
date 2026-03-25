//
//  ProfileScreen.swift
//  foundit
//
//  Created by Aryan Tandon on 3/24/26.
//

import SwiftUI

struct ProfileScreen: View {
    @State private var pushNotificationsEnabled = true
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Profile Header
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)

                    // TODO: Teammate — replace with authViewModel.currentUser?.displayName
                    Text("Dev User")
                        .font(.title2)
                        .fontWeight(.semibold)

                    // TODO: Teammate — replace with authViewModel.currentUser?.email
                    Text("dev@placeholder.com")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 24)

                Divider()

                // Menu Items
                VStack(spacing: 0) {
                    ProfileMenuItem(icon: "globe", title: "My post")
                    ProfileMenuItem(icon: "square.and.pencil", title: "Edit Profile")
                    ProfileMenuItem(icon: "lock", title: "Change Password")

                    // Push Notifications Toggle
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

                    // Logout
                    Button(action: {
                        // TODO: Teammate — call authViewModel.signOut()
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
                Button("OK", role: .cancel) {}
            } message: {
                Text("Auth not implemented yet. Your teammate will wire this up.")
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
    ProfileScreen()
}
