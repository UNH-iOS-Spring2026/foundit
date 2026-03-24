//
//  PostItemView.swift
//  foundit
//
//  Created by Divya Panthi on 24/03/2026.
//
import SwiftUI

// MARK: - AddReportView
struct PostItemView: View {

    @State private var selectedStatus: ItemStatus? = nil
    @State private var selectedCategory: String = "Books"
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker: Bool = false


    let categories = ["Books", "Electronics", "Accessories", "Clothing", "Keys", "Wallet", "Other"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // Post Type
                FormSectionLabel(title: "Select Report Type")

                VStack(spacing: 0) {
                    CheckboxRow(
                        label: "Lost Item",
                        isSelected: selectedStatus == .lost
                    ) {
                        selectedStatus = selectedStatus == .lost ? nil : .lost
                    }

                    Divider().padding(.leading, 50)

                    CheckboxRow(
                        label: "Found Item",
                        isSelected: selectedStatus == .found
                    ) {
                        selectedStatus = selectedStatus == .found ? nil : .found
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                FormSectionLabel(title: "Select Category")

                Menu {
                    ForEach(categories, id: \.self) { category in
                        Button(category) { selectedCategory = category }
                    }
                } label: {
                    HStack {
                        Text(selectedCategory)
                            .font(.system(size: 16))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                
                FormSectionLabel(title: "Select Date")
 
                //Date Picker
                VStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showDatePicker.toggle()
                        }
                    } label: {
                        HStack {
                            Text(selectedDate.formatted_MMM_d_yyyy)
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
 
                    // Inline calendar expands on tap
                    if showDatePicker {
                        Divider()
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(Color(red: 0.55, green: 0.60, blue: 0.85))
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Report Lost or Found Item")
        .navigationBarTitleDisplayMode(.inline)
//        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - FormSectionLabel
private struct FormSectionLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 14))
//            .foregroundStyle(.secondary)
            .padding(.bottom, -8)
    }
}

// MARK: - CheckboxRow
private struct CheckboxRow: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            isSelected
                                ? Color(red: 0.55, green: 0.60, blue: 0.85)
                                : Color(.systemGray3),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.55, green: 0.60, blue: 0.85))
                            .frame(width: 13, height: 13)
                    }
                }

                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: Preview
#Preview {
    NavigationStack {
        PostItemView()
    }
}
