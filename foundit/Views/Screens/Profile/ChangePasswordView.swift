//
//  ChangePasswordView.swift
//  foundit
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showCurrent = false
    @State private var showNew = false
    @State private var showConfirm = false
    @State private var showSuccess = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            VStack(spacing: 14) {
                CustomSecureField(text: $currentPassword, placeholder: "Current password", showPassword: $showCurrent)
                CustomSecureField(text: $newPassword, placeholder: "New password", showPassword: $showNew)
                CustomSecureField(text: $confirmPassword, placeholder: "Confirm new password", showPassword: $showConfirm)
            }

            if !authVM.errorMessage.isEmpty {
                Text(authVM.errorMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    let success = await authVM.changePassword(
                        currentPassword: currentPassword,
                        newPassword: newPassword,
                        confirmPassword: confirmPassword
                    )
                    if success { showSuccess = true }
                }
            } label: {
                Group {
                    if authVM.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Update Password")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 0.55, green: 0.60, blue: 0.85))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(authVM.isLoading)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { authVM.errorMessage = "" }
        .alert("Password Updated", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your password has been updated successfully.")
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
            .environmentObject(AuthViewModel())
    }
}
