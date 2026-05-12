//
//  PostItemView.swift
//  foundit
//
//  Created by Divya Panthi on 24/03/2026.
//
import SwiftUI
import PhotosUI
import CoreLocation
import MapKit
import FirebaseFirestore
import Combine

// MARK: - Location Search Completer
private class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func search(query: String) {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            suggestions = []
        } else {
            completer.queryFragment = query
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = Array(completer.results.prefix(5))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}

// MARK: - PostItemView
struct PostItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject private var tabRouter: TabRouter
    
    // Edit mode support
    var postToEdit: Post? = nil
    var isEditMode: Bool { postToEdit != nil }
    
    // Callback when post is successfully created
    var onPostCreated: (() -> Void)? = nil
    
    @State private var selectedType: PostType? = nil
    @State private var selectedCategory: String = "Books"
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker: Bool = false
    @State private var selectedImages: [UIImage] = []
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var mobileNumber: String = ""
    @State private var location: String = ""
    @State private var hideContactDetails: Bool = false
    @State private var showLocationPicker: Bool = false
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    @StateObject private var locationCompleter = LocationSearchCompleter()
    @FocusState private var locationFieldFocused: Bool
    @State private var existingPhotoUrls: [String] = []
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    
    
    let categories = ["Books", "Electronics", "Accessories", "Clothing", "Keys", "Wallet", "Other"]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                
                // Post Type
                FormSectionLabel(title: "Select Report Type")
                
                VStack(spacing: 0) {
                    CheckboxRow(
                        label: "Lost Item",
                        isSelected: selectedType == .lost
                    ) {
                        selectedType = selectedType == .lost ? nil : .lost
                    }
                    
                    Divider().padding(.leading, 50)
                    
                    CheckboxRow(
                        label: "Found Item",
                        isSelected: selectedType == .found
                    ) {
                        selectedType = selectedType == .found ? nil : .found
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
                
                FormSectionLabel(title: "Upload Images (up to \(maxImages))")

                Group {
                if totalImageCount == 0 {
                    // ── Empty state: full-width add button ───────────
                    PhotosPicker(
                        selection: $photoPickerItems,
                        maxSelectionCount: maxImages,
                        matching: .images
                    ) {
                        VStack(spacing: 10) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 32))
                                .foregroundStyle(Color(.systemGray3))
                            Text("Upload Images")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(.systemGray2))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                } else {
                    // ── Thumbnail strip ──────────────────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Existing URLs (edit mode)
                            ForEach(Array(existingPhotoUrls.enumerated()), id: \.offset) { index, urlString in
                                ZStack(alignment: .topTrailing) {
                                    PhaseCachedAsyncImage(url: URL(string: urlString)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable().scaledToFill()
                                        default:
                                            Color(.systemGray5)
                                        }
                                    }
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                    Button {
                                        existingPhotoUrls.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.white)
                                            .background(Color.black.opacity(0.5), in: Circle())
                                    }
                                    .offset(x: 6, y: -6)
                                }
                            }

                            // Newly selected local images
                            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, img in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                    Button {
                                        selectedImages.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.white)
                                            .background(Color.black.opacity(0.5), in: Circle())
                                    }
                                    .offset(x: 6, y: -6)
                                }
                            }

                            // Add more tile
                            if totalImageCount < maxImages {
                                PhotosPicker(
                                    selection: $photoPickerItems,
                                    maxSelectionCount: maxImages - totalImageCount,
                                    matching: .images
                                ) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 22, weight: .medium))
                                        Text("Add")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundStyle(Color(red: 0.55, green: 0.60, blue: 0.85))
                                    .frame(width: 90, height: 90)
                                    .background(Color(red: 0.55, green: 0.60, blue: 0.85).opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color(red: 0.55, green: 0.60, blue: 0.85).opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                } // Group
                .onChange(of: photoPickerItems) {
                    Task {
                        for item in photoPickerItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImages.append(image)
                            }
                        }
                        photoPickerItems = []
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
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search location…", text: $location)
                            .font(.system(size: 16))
                            .focused($locationFieldFocused)
                            .onChange(of: location) { _, newValue in
                                locationCompleter.search(query: newValue)
                            }
                        if !location.isEmpty {
                            Button {
                                location = ""
                                selectedCoordinate = nil
                                locationCompleter.suggestions = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(.systemGray3))
                            }
                        }
                        Button {
                            locationFieldFocused = false
                            showLocationPicker = true
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.pink)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    // Autocomplete suggestions
                    let suggestions = locationCompleter.suggestions
                    if locationFieldFocused && !suggestions.isEmpty {
                        Divider()
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                selectLocationSuggestion(suggestion)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color(red: 0.55, green: 0.60, blue: 0.85))
                                        .frame(width: 20)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        if !suggestion.subtitle.isEmpty {
                                            Text(suggestion.subtitle)
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            if suggestion != suggestions.last {
                                Divider().padding(.horizontal, 16)
                            }
                        }
                    }
                }
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
                        submitReport()
                    } label: {
                        Text(isEditMode ? "Update Post" : "Submit Report")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.55, green: 0.60, blue: 0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.5)
                    
                    Button {
                        dismiss()
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
        
        .navigationTitle(isEditMode ? "Edit Post" : "Report Lost or Found Item")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPostData()
        }
        .overlay {
            if postViewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Submitting...")
                        .padding(24)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .allowsHitTesting(!postViewModel.isLoading)
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text(isEditMode ? "Your post has been updated." : "Your report has been submitted.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(postViewModel.errorMessage ?? "Something went wrong. Please try again.")
        }
    }

    // MARK: - Helper Functions
    private let maxImages = 5

    private var totalImageCount: Int {
        existingPhotoUrls.count + selectedImages.count
    }

    private var isFormValid: Bool {
        guard let type = selectedType,
              !title.trimmingCharacters(in: .whitespaces).isEmpty,
              !descriptionText.trimmingCharacters(in: .whitespaces).isEmpty,
              !location.trimmingCharacters(in: .whitespaces).isEmpty,
              let _ = selectedCoordinate else {
            return false
        }
        return true
    }
    
    private func selectLocationSuggestion(_ suggestion: MKLocalSearchCompletion) {
        locationFieldFocused = false
        locationCompleter.suggestions = []
        let parts = [suggestion.title, suggestion.subtitle].filter { !$0.isEmpty }
        location = parts.joined(separator: ", ")
        Task {
            let request = MKLocalSearch.Request(completion: suggestion)
            if let response = try? await MKLocalSearch(request: request).start(),
               let placemark = response.mapItems.first?.placemark {
                selectedCoordinate = placemark.coordinate
            }
        }
    }

    private func loadPostData() {
        guard let post = postToEdit else { return }
        
        selectedType = post.type
        selectedCategory = post.category
        title = post.title
        descriptionText = post.description
        location = post.lastSeenLocationText
        selectedCoordinate = CLLocationCoordinate2D(
            latitude: post.lastSeenLocation.latitude,
            longitude: post.lastSeenLocation.longitude
        )
        existingPhotoUrls = post.photoUrls
        selectedDate = post.createdAt.dateValue()
    }
    
    private func submitReport() {
        guard let type = selectedType,
              let coordinate = selectedCoordinate else {
            return
        }

        postViewModel.didSucceed = false

        Task {
            let photoData: [Data] = selectedImages.compactMap {
                $0.jpegData(compressionQuality: 0.7)
            }

            let geoPoint = GeoPoint(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )

            if isEditMode, let postId = postToEdit?.id {
                await postViewModel.updatePost(
                    id: postId,
                    title: title,
                    description: descriptionText,
                    category: selectedCategory,
                    type: type,
                    location: geoPoint,
                    locationText: location,
                    photoData: photoData,
                    existingPhotoUrls: existingPhotoUrls,
                    reporterInfo: postToEdit?.reporterInfo  // Preserve reporter info
                )
            } else {
                await postViewModel.createPost(
                    title: title,
                    description: descriptionText,
                    category: selectedCategory,
                    type: type,
                    location: geoPoint,
                    locationText: location,
                    photoData: photoData
                )
            }

            if postViewModel.didSucceed {
                showSuccessAlert = true
                // Notify that a post was created (only for new posts, not edits)
                if !isEditMode {
                    onPostCreated?()
                }
            } else {
                showErrorAlert = true
            }
        }
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
            .environmentObject(PostViewModel())
            .environmentObject(TabRouter())
    }
}
