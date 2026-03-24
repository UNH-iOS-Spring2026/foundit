//
//  PostItemView.swift
//  foundit
//
//  Created by Divya Panthi on 24/03/2026.
//
import SwiftUI
import PhotosUI

// MARK: - PostItemView
struct PostItemView: View {
    
    @State private var selectedStatus: ItemStatus? = nil
    @State private var selectedCategory: String = "Books"
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var mobileNumber: String = ""
    @State private var location: String = ""
    @State private var hideContactDetails: Bool = false
    @State private var showLocationPicker: Bool = false
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    
    
    let categories = ["Books", "Electronics", "Accessories", "Clothing", "Keys", "Wallet", "Other"]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                
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
                
                FormSectionLabel(title: "Upload Image")
                
                PhotosPicker(
                    selection: $photoPickerItem,
                    matching: .images
                ) {
                    ZStack {
                        if let image = selectedImage {
                            // ── Selected image preview ─────────────────
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                
                                // Tap to change hint
                                Text("Tap to change")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.black.opacity(0.45))
                                    .clipShape(Capsule())
                                    .padding(10)
                            }
                        } else {
                            // Empty upload placeholder
                            VStack(spacing: 10) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color(.systemGray3))
                                Text("Upload Image")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(.systemGray2))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .onChange(of: photoPickerItem) {
                    Task {
                        if let data = try? await photoPickerItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImage = image
                        }
                    }
                }
                FormSectionLabel(title: "Title")
                
                TextField("", text: $title)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                FormSectionLabel(title: "Description")
                
                ZStack(alignment: .topLeading) {
                    if descriptionText.isEmpty {
                        Text("Enter description...")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(.placeholderText))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }
                    TextEditor(text: $descriptionText)
                        .font(.system(size: 16))
                        .frame(height: 50)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .scrollContentBackground(.hidden)
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                
                FormSectionLabel(title: "Mobile Number")
                TextField("", text: $mobileNumber)
                    .font(.system(size: 16))
                    .keyboardType(.phonePad)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                FormSectionLabel(title: "Location")
                HStack {
                    TextField("", text: $location)
                        .font(.system(size: 16))
                    Spacer()
                    Button {
                        showLocationPicker = true
                    } label: {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.pink)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .sheet(isPresented: $showLocationPicker) {
                    LocationPickerView(
                        selectedCoordinate: $selectedCoordinate,
                        locationText: $location
                    )
                }
                Button {
                    hideContactDetails.toggle()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(
                                    hideContactDetails
                                    ? Color(red: 0.55, green: 0.60, blue: 0.85)
                                    : Color(.systemGray3),
                                    lineWidth: 2
                                )
                                .frame(width: 22, height: 22)
                            
                            if hideContactDetails {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(red: 0.55, green: 0.60, blue: 0.85))
                                    .frame(width: 13, height: 13)
                            }
                        }
                        
                        Text("Hide my contact details (Only allow chat)")
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                
                VStack(spacing: 12) {
                    Button {
                        // TODO: submit report
                    } label: {
                        Text("Submit Report")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.55, green: 0.60, blue: 0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button {
                        // TODO: dismiss
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.top, 8)
                
            }
            
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 32)
        
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
