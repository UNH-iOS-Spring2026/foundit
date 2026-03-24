//
//  CustomFields.swift
//  foundit
//
//  Created by Ashish Khadka on 3/18/26.
//

import SwiftUI

struct CustomTextField: View {
	@Binding var text: String
	let placeholder: String

	var body: some View {
		TextField(placeholder, text: $text)
			.font(.system(size: 16))
			.padding(.horizontal, 16)
			.frame(height: 50)
			.background(Color(.systemGray6))
			.clipShape(RoundedRectangle(cornerRadius: 12))
			.autocorrectionDisabled(true)
			.textInputAutocapitalization(.never)
	}
}

struct CustomSecureField: View {
	@Binding var text: String
	let placeholder: String
	@Binding var showPassword: Bool

	var body: some View {
		HStack {
			Group {
				if showPassword {
					TextField(placeholder, text: $text)
				} else {
					SecureField(placeholder, text: $text)
				}
			}
			.font(.system(size: 16))

			Button {
				showPassword.toggle()
			} label: {
				Image(systemName: showPassword ? "eye.slash" : "eye")
					.foregroundColor(.black.opacity(0.7))
			}
		}
		.padding(.horizontal, 16)
		.frame(height: 50)
		.background(Color(.systemGray6))
		.clipShape(RoundedRectangle(cornerRadius: 12))
		.autocorrectionDisabled(true)
		.textInputAutocapitalization(.never)
	}
}
