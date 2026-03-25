//
//  ChatDetailView.swift
//  foundit
//

import SwiftUI

struct ChatDetailView: View {
    let chatId: String
    let contactName: String
    @EnvironmentObject var chatViewModel: ChatViewModel
    @State private var draftText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(chatViewModel.messages) { message in
                            let isFromUser = message.senderId == AppConfig.placeholderUserId
                            HStack(alignment: .bottom) {
                                if isFromUser {
                                    Spacer(minLength: 40)
                                    bubble(content: AnyView(Text(message.text).foregroundStyle(.primary)), isFromUser: true)
                                } else {
                                    bubble(content: AnyView(Text(message.text).foregroundStyle(.primary)), isFromUser: false)
                                    Spacer(minLength: 40)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
            }

            Divider()

            HStack(spacing: 8) {
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
        }
        .navigationTitle(contactName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            chatViewModel.listenToMessages(chatId: chatId)
        }
        .onDisappear {
            chatViewModel.stopListening()
        }
    }

    @ViewBuilder
    private func bubble(content: AnyView, isFromUser: Bool) -> some View {
        content
            .padding(10)
            .background(isFromUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func sendMessage() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            await chatViewModel.sendMessage(chatId: chatId, text: trimmed)
        }
        draftText = ""
    }
}

#Preview {
    NavigationStack {
        ChatDetailView(chatId: "test", contactName: "Campus Police")
            .environmentObject(ChatViewModel())
    }
}
