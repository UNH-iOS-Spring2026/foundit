//
//  PostDetailView.swift
//  foundit
//
//  Created by Divya Panthi on 24/03/2026.
//

import SwiftUI
import MapKit
import FirebaseFirestore

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

                        Text(viewModel.reporterName)
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
                    .disabled(true)   // non-interactive, tap to open Maps if needed
                    
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.pink)
                            .font(.system(size: 16))
                        Text(item.lastSeenLocationText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                
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
            ChatDetailView(chatId: chatId, contactName: "Campus Police")
                .environmentObject(resolvedChatViewModel)
        }
        .task {
            await viewModel.fetchReporterName(userId: item.createdBy)
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
