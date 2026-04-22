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
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var viewModel = PostViewModel()
    @StateObject private var fallbackChatViewModel = ChatViewModel()
    @State private var similarItems: [Post] = []
    @State private var activeChatId: String?
    @State private var isCreatingChat = false
    @State private var showQRSheet = false
    @State private var qrPayload: QRClaimPayload?
    @State private var isGeneratingQR = false
    @State private var qrErrorMessage: String?
    @State private var showScanner = false
    @State private var claimListener: ListenerRegistration?
    
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
    
    // Police: fetch/provision the Item, write a fresh ClaimToken, then open the drawer.
    private func generateClaimQR() {
        guard !isGeneratingQR else { return }
        let postId = item.id ?? ""
        guard !postId.isEmpty else {
            qrErrorMessage = "Missing post id — cannot generate code."
            return
        }
        isGeneratingQR = true
        qrErrorMessage = nil
        Task {
            do {
                let itemService = ItemService()
                let tokenService = ClaimTokenService()
                let existing = try await itemService.fetchItemsByPost(postId: postId).first
                let itemId: String
                if let existingId = existing?.id {
                    itemId = existingId
                } else {
                    // No Item yet (police may be generating a QR before chat flow). Provision one now.
                    let fresh = Item(
                        sourcePostId: postId,
                        status: .waitingForPickup,
                        qrCodeValue: UUID().uuidString,
                        receivedAt: Timestamp(),
                        returnedAt: nil,
                        foundBy: item.createdBy,
                        collectedBy: AppConfig.currentUserId
                    )
                    itemId = try await itemService.createItem(fresh)
                }

                let payload = QRClaimPayload.generate(for: postId)
                try await tokenService.createToken(
                    postId: postId,
                    itemId: itemId,
                    nonce: payload.nonce,
                    expiresAt: payload.expiresAt,
                    createdByPoliceId: AppConfig.currentUserId
                )

                qrPayload = payload
                showQRSheet = true
                startClaimListener(nonce: payload.nonce)
            } catch {
                qrErrorMessage = "Couldn't generate QR: \(error.localizedDescription)"
            }
            isGeneratingQR = false
        }
    }

    // Police-side: watch for the student's claim. When the token gets consumed,
    // close the drawer and jump the officer into the chat thread for this claim.
    private func startClaimListener(nonce: String) {
        claimListener?.remove()
        let service = ClaimTokenService()
        claimListener = service.observeConsumption(nonce: nonce) { consumedByUserId in
            claimListener?.remove()
            claimListener = nil
            showQRSheet = false
            Task {
                if let chat = try? await ChatService().fetchChat(
                    forPostId: item.id ?? "",
                    userId: consumedByUserId
                ) {
                    activeChatId = chat.id
                }
            }
        }
    }

    private func stopClaimListener() {
        claimListener?.remove()
        claimListener = nil
    }

    // Demo affordance: redeems the current QR token as if a student scanned it.
    // Uses the existing chat's userId when available so the listener lands the
    // officer in the right chat thread. Falls back to the current user's uid
    // when no chat exists yet (e.g. QR generated before chat was started).
    private func simulateStudentScan() {
        guard let payload = qrPayload else {
            qrErrorMessage = "Generate a code first, then simulate."
            return
        }
        let postId = item.id ?? ""
        Task {
            do {
                let simulatedUserId: String
                if let chat = try await ChatService().fetchChat(
                    forPostId: postId,
                    userId: AppConfig.currentUserId
                ) {
                    simulatedUserId = chat.userId
                } else if let chat = try await ChatService().fetchAllPoliceChats()
                    .first(where: { $0.postId == postId }) {
                    simulatedUserId = chat.userId
                } else {
                    simulatedUserId = AppConfig.currentUserId
                }

                let service = ClaimTokenService()
                let token = try await service.fetchToken(nonce: payload.nonce)
                try await service.redeemToken(
                    token,
                    consumedByUserId: simulatedUserId
                )
                // observeConsumption will fire and handle drawer dismiss + navigation.
            } catch {
                qrErrorMessage = "Simulate failed: \(error.localizedDescription)"
            }
        }
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
                
                // Police-only: generate a one-time, time-limited QR code for handoff
                if authVM.isAdmin {
                    Button {
                        generateClaimQR()
                    } label: {
                        HStack(spacing: 8) {
                            if isGeneratingQR {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(Color(red: 0.55, green: 0.60, blue: 0.85))
                            } else {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Show QR Code")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundStyle(Color(red: 0.55, green: 0.60, blue: 0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(red: 0.55, green: 0.60, blue: 0.85), lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isGeneratingQR)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    if let qrErrorMessage {
                        Text(qrErrorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                }

                // Owner of a lost post: scan the QR the officer is showing, to claim.
                if !authVM.isAdmin && isOwnPost && item.type == .lost {
                    Button {
                        showScanner = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Scan QR to Claim")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.55, green: 0.60, blue: 0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                }

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
            ChatDetailView(
                chatId: chatId,
                contactName: authVM.isAdmin ? (reporterName.isEmpty ? "Student" : reporterName) : "Campus Police",
                postId: item.id ?? "",
                isAdmin: authVM.isAdmin
            )
            .environmentObject(resolvedChatViewModel)
        }
        .sheet(isPresented: $showQRSheet, onDismiss: {
            stopClaimListener()
        }) {
            QRCodeDrawerView(
                itemCode: qrPayload?.encoded ?? "",
                itemTitle: item.title,
                expiresAt: qrPayload?.expiresAt,
                onSimulateClaim: nil // authVM.isAdmin ? { simulateStudentScan() } : nil
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showScanner) {
            QRScannerView(claimPostId: item.id ?? "") { chatId in
                showScanner = false
                if let chatId {
                    activeChatId = chatId
                }
            }
        }
        .task {
            // Only fetch reporter name if not already in reporterInfo
            if item.reporterInfo == nil {
                await viewModel.fetchReporterName(userId: item.createdBy)
            }
            similarItems = await viewModel.fetchSimilarPosts(to: item, limit: 6)
        }
        .onDisappear {
            stopClaimListener()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PostDetailView(item: Post.mockItems[0])
            .environmentObject(AuthViewModel())
    }
}
