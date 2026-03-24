import SwiftUI

struct MessageScreen: View {
    var body: some View {
        NavigationStack {
            List(sampleConversations) { convo in
                NavigationLink(value: convo.id) {
                    HStack(spacing: 12) {
                        // Thumbnail placeholder
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 48, height: 48)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(convo.itemName) || \(convo.itemID)")
                                .font(.headline)
                            Text(convo.lastMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Inbox")
            .navigationDestination(for: UUID.self) { id in
                ChatDetailView(contactName: "Campus Police", messages: sampleMessages)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MessageScreen()
    }
}
