//
//  ChatViewModel.swift
//  foundit
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [Chat] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false
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

    func listenToMessages(chatId: String) {
        stopListening()
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

    func sendMessage(chatId: String, text: String, senderId: String = AppConfig.placeholderUserId) async {
        let message = Message(
            senderId: senderId,
            senderRole: .student,
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

    func stopListening() {
        cancellables.removeAll()
    }
}

