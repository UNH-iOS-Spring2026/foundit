//
//  EditProfileView.swift
//  foundit
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""

    private var hasChanges: Bool {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines) != authVM.currentDisplayName
            && !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                CustomTextField(text: $displayName, placeholder: "Your name")
                    .disabled(!authVM.canChangeName || authVM.isLoading)
                    .opacity(authVM.canChangeName ? 1 : 0.5)

                if !authVM.canChangeName, let nextDate = authVM.nextNameChangeDate {
                    Text("You can change your name again on \(nextDate.formatted(date: .long, time: .omitted)).")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            if !authVM.errorMessage.isEmpty {
                Text(authVM.errorMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(.red)
            }

            if authVM.canChangeName {
                Button {
                    Task {
                        let success = await authVM.updateDisplayName(displayName)
                        if success { dismiss() }
                    }
                } label: {
                    Group {
                        if authVM.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Changes")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Color(red: 0.55, green: 0.60, blue: 0.85)
                            .opacity(hasChanges ? 1 : 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!hasChanges || authVM.isLoading)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { authVM.errorMessage = "" }
        .task {
            await authVM.fetchNameChangedAt()
            displayName = authVM.currentDisplayName
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(AuthViewModel())
    }
}
