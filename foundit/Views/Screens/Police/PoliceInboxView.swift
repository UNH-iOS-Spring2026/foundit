//
//  PoliceInboxView.swift
//  foundit
//

import SwiftUI
import FirebaseAuth

struct PoliceInboxView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @State private var studentNames: [String: String] = [:]
    @State private var selectedStatus: Chat.Status? = nil
    private let userService = UserService()

    private var filteredConversations: [Chat] {
        guard let filter = selectedStatus else { return chatViewModel.conversations }
        return chatViewModel.conversations.filter { $0.status == filter }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Header
                HStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "shield.fill")
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(authVM.currentUser?.displayName ?? "Officer")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Campus Police")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .background(Color(FounditColors.primary))

                // MARK: Filter pills
                if !chatViewModel.conversations.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            PoliceFilterPill(title: "All", isSelected: selectedStatus == nil) {
                                selectedStatus = nil
                            }
                            PoliceFilterPill(title: "Active", isSelected: selectedStatus == .active) {
                                selectedStatus = .active
                            }
                            PoliceFilterPill(title: "Pickup", isSelected: selectedStatus == .waitingForPickup) {
                                selectedStatus = .waitingForPickup
                            }
                            PoliceFilterPill(title: "Closed", isSelected: selectedStatus == .closed) {
                                selectedStatus = .closed
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .background(Color(.systemBackground))
                }

                // MARK: Inbox list
                Group {
                    if chatViewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if chatViewModel.conversations.isEmpty {
                        Spacer()
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
                        Spacer()
                    } else if filteredConversations.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("No matching cases")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Try a different filter")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    } else {
                        List(filteredConversations) { chat in
                            NavigationLink(value: chat) {
                                HStack(spacing: 12) {
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

                                            Text(statusLabel(for: chat.status))
                                                .font(.caption2.weight(.semibold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    Capsule()
                                                        .fill(statusColor(for: chat.status).opacity(0.15))
                                                )
                                                .foregroundStyle(statusColor(for: chat.status))
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
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Chat.self) { chat in
                ChatDetailView(
                    chatId: chat.id ?? "",
                    contactName: studentNames[chat.userId] ?? "Student",
                    postId: chat.postId,
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

    private func statusLabel(for status: Chat.Status) -> String {
        switch status {
        case .active: return "Active"
        case .waitingForPickup: return "Pickup"
        case .closed: return "Closed"
        }
    }

    private func statusColor(for status: Chat.Status) -> Color {
        switch status {
        case .active: return .green
        case .waitingForPickup: return .orange
        case .closed: return .red
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

private struct PoliceFilterPill: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? Color(red: 0.55, green: 0.60, blue: 0.85)
                        : Color(.systemGray5)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PoliceInboxView()
        .environmentObject(ChatViewModel())
        .environmentObject(AuthViewModel())
}
