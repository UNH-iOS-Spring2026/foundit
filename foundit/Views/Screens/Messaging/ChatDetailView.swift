import SwiftUI

struct ChatDetailView: View {
    let contactName: String
    @State var messages: [ChatMessage]
    @State private var draftText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            if message.isImage {
                                // Image placeholder bubble (received)
                                HStack(alignment: .bottom) {
                                    bubble(content: AnyView(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 220, height: 140)
                                    ), isFromUser: false)
                                    Spacer(minLength: 40)
                                }
                            } else if let text = message.text {
                                HStack(alignment: .bottom) {
                                    if message.isFromUser {
                                        Spacer(minLength: 40)
                                        bubble(content: AnyView(Text(text).foregroundStyle(.primary)), isFromUser: true)
                                    } else {
                                        bubble(content: AnyView(Text(text).foregroundStyle(.primary)), isFromUser: false)
                                        Spacer(minLength: 40)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
            }

            Divider()

            // Input bar
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
        let new = ChatMessage(id: UUID(), text: trimmed, isFromUser: true, isImage: false)
        messages.append(new)
        draftText = ""
    }
}

#Preview {
    NavigationStack {
        ChatDetailView(contactName: "Campus Police", messages: sampleMessages)
    }
}
