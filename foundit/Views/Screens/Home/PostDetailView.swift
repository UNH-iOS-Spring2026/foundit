//
//  PostDetailView.swift
//  foundit
//
//  Created by Divya Panthi on 24/03/2026.
//

import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

struct PostDetailView: View {
    let item: Post
    var chatViewModel: ChatViewModel?
    @StateObject private var viewModel = PostViewModel()
    @StateObject private var fallbackChatViewModel = ChatViewModel()
    @State private var similarItems: [Post] = []
    @State private var activeChatId: String?
    @State private var isCreatingChat = false
    
    private var resolvedChatViewModel: ChatViewModel {
        chatViewModel ?? fallbackChatViewModel
    }
    
    // Check if current user is the post creator
    private var isOwnPost: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return false
        }
        return item.createdBy == currentUserId
    }
    
    // Get reporter name from reporterInfo if available, otherwise use fetched name
    private var reporterName: String {
        if let reporterInfo = item.reporterInfo {
            return reporterInfo.name
        }
        return viewModel.reporterName
    }
    
    // Open location in Apple Maps with directions
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: item.coordinate.latitude,
            longitude: item.coordinate.longitude
        )
        
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = item.lastSeenLocationText.isEmpty ? item.title : item.lastSeenLocationText
        
        // Open Maps with directions option
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                
                ItemImageCarouselView(images: item.photoUrls)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                VStack(alignment: .leading, spacing: 8) {
                    
                    Text(item.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text(item.category)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Text(item.formattedDate)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Text(item.formattedTime)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Reported by")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(.systemGray4))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundStyle(Color(.systemGray))
                            )

                        Text(reporterName)
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(item.description)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Location")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    // Map
                    Map(position: .constant(
                        .region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(
                                    latitude: item.coordinate.latitude,
                                    longitude: item.coordinate.longitude
                                ),
                                span: MKCoordinateSpan(
                                    latitudeDelta: 0.05,
                                    longitudeDelta: 0.05
                                )
                            )
                        )
                    )) {
                        Marker("", coordinate: CLLocationCoordinate2D(
                            latitude: item.coordinate.latitude,
                            longitude: item.coordinate.longitude
                        ))
                        .tint(Color(red: 0.55, green: 0.60, blue: 0.85))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(true)
                    .onTapGesture {
                        openInMaps()
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color(.systemGray5), lineWidth: 1)
                    )
                    
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.pink)
                            .font(.system(size: 16))
                        Text(item.lastSeenLocationText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        // "Open in Maps" button
                        Button {
                            openInMaps()
                        } label: {
                            HStack(spacing: 4) {
                                Text("Get Directions")
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(Color(red: 0.55, green: 0.60, blue: 0.85))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                
                // Only show "Take Action" button if this is NOT the current user's post
                if !isOwnPost {
                    Button {
                        guard !isCreatingChat else { return }
                        isCreatingChat = true
                        Task {
                            let chatService = ChatService()
                            let userId = AppConfig.placeholderUserId
                            do {
                                if let existing = try await chatService.fetchChat(forPostId: item.id ?? "", userId: userId) {
                                    activeChatId = existing.id
                                } else {
                                    let now = Timestamp()
                                    let chat = Chat(
                                        postId: item.id ?? "",
                                        userId: userId,
                                        policeId: "campus-police-001",
                                        itemTitle: item.title,
                                        itemImageUrl: item.primaryImageUrl,
                                        lastMessage: "",
                                        lastMessageAt: now,
                                        status: .active,
                                        createdAt: now,
                                        updatedAt: now
                                    )
                                    let chatId = try await chatService.createChat(chat)
                                    activeChatId = chatId
                                }
                            } catch {
                                print("[TakeAction] Error: \(error)")
                            }
                            isCreatingChat = false
                        }
                    } label: {
                        if isCreatingChat {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.55, green: 0.60, blue: 0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            Text("Take Action")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.55, green: 0.60, blue: 0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .disabled(isCreatingChat)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Similar Items")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
 
                    if similarItems.isEmpty {
                        Text("No similar items found")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(similarItems) { similarItem in
                                NavigationLink {
                                    PostDetailView(item: similarItem)
                                } label: {
                                    ItemCardView(item: similarItem)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
                
            }
        }
        .navigationTitle("Report Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .navigationDestination(item: $activeChatId) { chatId in
            ChatDetailView(chatId: chatId, contactName: "Campus Police", postId: item.id ?? "")
                .environmentObject(resolvedChatViewModel)
        }
        .task {
            // Only fetch reporter name if not already in reporterInfo
            if item.reporterInfo == nil {
                await viewModel.fetchReporterName(userId: item.createdBy)
            }
            similarItems = await viewModel.fetchSimilarPosts(to: item, limit: 6)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PostDetailView(item: Post.mockItems[0])
    }
}
