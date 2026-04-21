//
//  ChatViewModel.swift
//  foundit
//

import Foundation
import UIKit
import FirebaseFirestore
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [Chat] = []
    @Published var messages: [Message] = []
    @Published var chatStatus: Chat.Status?
    @Published var isLoading = false
    @Published var isSendingPhoto = false
    @Published var errorMessage: String?

    private let chatService = ChatService()
    private var cancellables = Set<AnyCancellable>()

    func fetchConversations(userId: String = AppConfig.placeholderUserId) async {
        isLoading = true
        errorMessage = nil
        do {
            conversations = try await chatService.fetchChats(forUserId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Fetches all conversations for the police shared inbox.
    func fetchPoliceConversations() async {
        isLoading = true
        errorMessage = nil
        do {
            conversations = try await chatService.fetchAllPoliceChats()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func listenToMessages(chatId: String) {
        stopListening()

        chatService.chatPublisher(chatId: chatId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] chat in
                    self?.chatStatus = chat?.status
                }
            )
            .store(in: &cancellables)

        chatService.messagesPublisher(chatId: chatId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] msgs in
                    self?.messages = msgs
                }
            )
            .store(in: &cancellables)
    }

    func sendMessage(chatId: String, text: String, isAdmin: Bool = false) async {
        let senderId = isAdmin ? AppConfig.policeSenderId : AppConfig.currentUserId
        let senderRole: Message.SenderRole = isAdmin ? .police : .student
        let message = Message(
            senderId: senderId,
            senderRole: senderRole,
            type: .text,
            text: text,
            photoUrl: nil,
            sentAt: Timestamp()
        )
        do {
            try await chatService.sendMessage(chatId: chatId, message: message)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendPhoto(chatId: String, imageData: Data, isAdmin: Bool = false) async {
        isSendingPhoto = true
        do {
            guard let uiImage = UIImage(data: imageData),
                  let jpegData = uiImage.jpegData(compressionQuality: 0.5) else {
                errorMessage = "Failed to process image"
                isSendingPhoto = false
                return
            }

            let path = "chats/\(chatId)/\(UUID().uuidString).jpg"
            let downloadUrl = try await StorageService().uploadImage(data: jpegData, path: path)

            let senderId = isAdmin ? AppConfig.policeSenderId : AppConfig.currentUserId
            let senderRole: Message.SenderRole = isAdmin ? .police : .student
            let message = Message(
                senderId: senderId,
                senderRole: senderRole,
                type: .photo,
                text: "",
                photoUrl: downloadUrl,
                sentAt: Timestamp()
            )
            try await chatService.sendMessage(chatId: chatId, message: message)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSendingPhoto = false
    }

    func startChat(for post: Post) async -> String? {
        do {
            let userId = AppConfig.placeholderUserId
            if let existing = try await chatService.fetchChat(forPostId: post.id ?? "", userId: userId) {
                return existing.id
            }
            let now = Timestamp()
            let chat = Chat(
                postId: post.id ?? "",
                userId: userId,
                policeId: "campus-police-001",
                itemTitle: post.title,
                itemImageUrl: post.primaryImageUrl,
                lastMessage: "",
                lastMessageAt: now,
                status: .active,
                createdAt: now,
                updatedAt: now
            )
            let chatId = try await chatService.createChat(chat)
            return chatId
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func markReadyForPickup(chatId: String, postId: String) async {
        do {
            try await chatService.markReadyForPickup(chatId: chatId, postId: postId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopListening() {
        cancellables.removeAll()
    }
}

