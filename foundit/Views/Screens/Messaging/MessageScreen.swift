//
//  MessageScreen.swift
//  foundit
//

import SwiftUI

struct MessageScreen: View {
    @EnvironmentObject var chatViewModel: ChatViewModel

    var body: some View {
        NavigationStack {
            Group {
                if chatViewModel.isLoading {
                    ProgressView()
                } else if chatViewModel.conversations.isEmpty {
                    Text("No conversations yet")
                        .foregroundStyle(.secondary)
                } else {
                    List(chatViewModel.conversations) { chat in
                        NavigationLink(value: chat.id ?? "") {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 48, height: 48)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Post: \(chat.postId)")
                                        .font(.headline)
                                    Text(chat.lastMessage)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Inbox")
            .navigationDestination(for: String.self) { chatId in
                ChatDetailView(chatId: chatId, contactName: "Campus Police")
            }
            .onAppear {
                Task {
                    await chatViewModel.fetchConversations()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MessageScreen()
            .environmentObject(ChatViewModel())
    }
}
