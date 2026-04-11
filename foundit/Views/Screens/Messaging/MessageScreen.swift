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
                                // Thumbnail
                                if let urlString = chat.itemImageUrl, let url = URL(string: urlString) {
                                    CachedAsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.gray.opacity(0.15))
                                                ProgressView()
                                            }
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        case .failure:
                                            Image(systemName: "photo")
                                                .foregroundStyle(.secondary)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        @unknown default:
                                            Color.gray.opacity(0.2)
                                        }
                                    }
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.15))
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundStyle(.secondary)
                                        )
                                        .frame(width: 48, height: 48)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(chat.itemTitle)
                                            .font(.headline)
                                            .lineLimit(1)

                                        // Status badge
                                        Text(chat.status == .closed ? "Closed" : "Active")
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(chat.status == .closed ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                                            )
                                            .foregroundStyle(chat.status == .closed ? .red : .green)
                                    }

                                    Text(chat.lastMessage)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Inbox")
            .navigationDestination(for: String.self) { chatId in
                ChatDetailView(chatId: chatId, contactName: "Campus Police").environmentObject(chatViewModel)
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
