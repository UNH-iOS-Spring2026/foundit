//
//  ChatDetailView.swift
//  foundit
//

import SwiftUI
import PhotosUI
import FirebaseFirestore

private struct PickedPhoto: Transferable {
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            PickedPhoto(data: data)
        }
    }
}

struct ChatDetailView: View {
    let chatId: String
    let contactName: String
    var postId: String = ""
    var isAdmin: Bool = false
    var pendingItemTitle: String? = nil
    var pendingItemImageUrl: String? = nil
    @EnvironmentObject var chatViewModel: ChatViewModel
    @State private var resolvedChatId: String = ""
    @State private var draftText: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showReadyForPickupAlert = false
    @State private var showReturnedAlert = false
    @State private var showErrorAlert = false
    @State private var isCreatingChat = false

    private var effectiveChatId: String {
        resolvedChatId.isEmpty ? chatId : resolvedChatId
    }

    private var isPending: Bool {
        effectiveChatId.isEmpty
    }

    private var isWaitingForPickup: Bool {
        chatViewModel.chatStatus == .waitingForPickup
    }

    private var isChatInputDisabled: Bool {
        !isAdmin && isWaitingForPickup
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(chatViewModel.messages) { message in
                            messageRow(for: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .onChange(of: chatViewModel.messages.count) {
                    if let lastId = chatViewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let lastId = chatViewModel.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }

            Divider()

            // Police action bar
            if isAdmin {
                if isWaitingForPickup {
                    VStack(spacing: 8) {
                        Label("Awaiting student pickup", systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                            .padding(.top, 10)
                        Button {
                            showReturnedAlert = true
                        } label: {
                            Label("Mark as Returned", systemImage: "archivebox.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                } else if chatViewModel.chatStatus == .active {
                    Button {
                        showReadyForPickupAlert = true
                    } label: {
                        Label("Mark as Ready for Pickup", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }

            // Chat input (disabled for students when waiting for pickup)
            if isChatInputDisabled {
                Text("This chat is locked — awaiting item pickup.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                HStack(spacing: 8) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .imageScale(.large)
                    }
                    .disabled(chatViewModel.isSendingPhoto)

                    TextField("Type message here....", text: $draftText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .imageScale(.large)
                    }
                    .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.all, 12)
                .background(.bar)
                .overlay {
                    if chatViewModel.isSendingPhoto {
                        ProgressView()
                    }
                }
                .onChange(of: selectedPhoto) {
                    guard let item = selectedPhoto else { return }
                    Task {
                        if let photo = try? await item.loadTransferable(type: PickedPhoto.self) {
                            guard let targetChatId = await ensureChatCreated() else { return }
                            await chatViewModel.sendPhoto(chatId: targetChatId, imageData: photo.data, isAdmin: isAdmin)
                        }
                        selectedPhoto = nil
                    }
                }
            }
        }
        .navigationTitle(contactName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !effectiveChatId.isEmpty {
                chatViewModel.listenToMessages(chatId: effectiveChatId)
            }
        }
        .onDisappear {
            chatViewModel.stopListening()
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { chatViewModel.errorMessage = nil }
        } message: {
            Text(chatViewModel.errorMessage ?? "")
        }
        .onChange(of: chatViewModel.errorMessage) {
            showErrorAlert = chatViewModel.errorMessage != nil
        }
        .alert("Mark as Returned", isPresented: $showReturnedAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                Task {
                    await chatViewModel.markReturned(chatId: effectiveChatId, postId: postId)
                }
            }
        } message: {
            Text("Mark this item as returned to its owner? This will close the case.")
        }
        .alert("Mark as Ready for Pickup", isPresented: $showReadyForPickupAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm") {
                Task {
                    await chatViewModel.markReadyForPickup(chatId: effectiveChatId, postId: postId)
                }
            }
        } message: {
            Text("Mark this item as ready for pickup? The student will be notified in the chat.")
        }
    }

    @ViewBuilder
    private func messageRow(for message: Message) -> some View {
        if message.type == .system {
            HStack {
                Spacer()
                Text(message.text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Spacer()
            }
        } else {
            let isOwnMessage = isAdmin
                ? message.senderRole == .police
                : message.senderId == AppConfig.currentUserId
            HStack(alignment: .bottom) {
                if isOwnMessage {
                    Spacer(minLength: 40)
                    bubble(content: AnyView(messageContent(for: message)), isFromUser: true)
                } else {
                    bubble(content: AnyView(messageContent(for: message)), isFromUser: false)
                    Spacer(minLength: 40)
                }
            }
        }
    }

    @ViewBuilder
    private func messageContent(for message: Message) -> some View {
        if message.type == .photo, let urlString = message.photoUrl, let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                default:
                    ProgressView()
                }
            }
            .frame(maxWidth: 250, maxHeight: 250)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Text(message.text)
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private func bubble(content: AnyView, isFromUser: Bool) -> some View {
        content
            .padding(10)
            .background(isFromUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func ensureChatCreated() async -> String? {
        if !effectiveChatId.isEmpty { return effectiveChatId }
        guard !isCreatingChat else { return nil }
        isCreatingChat = true
        defer { isCreatingChat = false }
        let now = Timestamp()
        let chat = Chat(
            postId: postId,
            userId: AppConfig.currentUserId,
            policeId: "campus-police-001",
            itemTitle: pendingItemTitle ?? "",
            itemImageUrl: pendingItemImageUrl,
            lastMessage: "",
            lastMessageAt: now,
            status: .active,
            createdAt: now,
            updatedAt: now
        )
        do {
            let newChatId = try await ChatService().createChat(chat)
            resolvedChatId = newChatId
            chatViewModel.listenToMessages(chatId: newChatId)
            return newChatId
        } catch {
            chatViewModel.errorMessage = error.localizedDescription
            return nil
        }
    }

    private func sendMessage() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let textToSend = trimmed
        draftText = ""
        Task {
            guard let targetChatId = await ensureChatCreated() else { return }
            await chatViewModel.sendMessage(chatId: targetChatId, text: textToSend, isAdmin: isAdmin)
        }
    }
}

#Preview {
    NavigationStack {
        ChatDetailView(chatId: "test", contactName: "Campus Police")
            .environmentObject(ChatViewModel())
    }
}
