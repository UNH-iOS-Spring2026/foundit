//
//  PoliceInboxView.swift
//  foundit
//

import SwiftUI

struct PoliceInboxView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel

    @State private var studentNames: [String: String] = [:]
    private let userService = UserService()

    var body: some View {
        NavigationStack {
            Group {
                if chatViewModel.isLoading {
                    ProgressView()
                } else if chatViewModel.conversations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "message")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No messages yet")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Student messages will appear here")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List(chatViewModel.conversations) { chat in
                        NavigationLink(value: chat) {
                            HStack(spacing: 12) {
                                // Thumbnail
                                if let urlString = chat.itemImageUrl, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        case .failure:
                                            imagePlaceholder
                                        default:
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.gray.opacity(0.15))
                                                ProgressView()
                                            }
                                        }
                                    }
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    imagePlaceholder
                                        .frame(width: 48, height: 48)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(chat.itemTitle)
                                            .font(.headline)
                                            .lineLimit(1)

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

                                    Text(studentNames[chat.userId] ?? "Student")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)

                                    if !chat.lastMessage.isEmpty {
                                        Text(chat.lastMessage)
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Inbox")
            .navigationDestination(for: Chat.self) { chat in
                ChatDetailView(
                    chatId: chat.id ?? "",
                    contactName: studentNames[chat.userId] ?? "Student",
                    isAdmin: true
                )
                .environmentObject(chatViewModel)
            }
            .onAppear {
                Task {
                    await chatViewModel.fetchPoliceConversations()
                    await loadStudentNames()
                }
            }
        }
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.15))
            .overlay(
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            )
    }

    private func loadStudentNames() async {
        for chat in chatViewModel.conversations {
            guard studentNames[chat.userId] == nil else { continue }
            do {
                let user = try await userService.fetchUser(uid: chat.userId)
                studentNames[chat.userId] = user.displayName
            } catch {
                studentNames[chat.userId] = "Student"
            }
        }
    }
}

#Preview {
    PoliceInboxView()
        .environmentObject(ChatViewModel())
}
