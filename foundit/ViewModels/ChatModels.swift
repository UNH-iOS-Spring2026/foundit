import SwiftUI

// Data Models
struct Conversation: Identifiable {
    let id: UUID
    let itemName: String
    let itemID: String
    let lastMessage: String
}

struct ChatMessage: Identifiable {
    let id: UUID
    let text: String?
    let isFromUser: Bool
    let isImage: Bool
}

// Sample Data 
let sampleConversations: [Conversation] = [
    Conversation(id: UUID(), itemName: "Grey Water Bottle", itemID: "ID-355", lastMessage: "Police: Sounds Good"),
    Conversation(id: UUID(), itemName: "Blue Water Bottle", itemID: "ID-354", lastMessage: "Police: Welcome")
]

let sampleMessages: [ChatMessage] = [
    ChatMessage(id: UUID(), text: nil, isFromUser: false, isImage: true),
    ChatMessage(id: UUID(), text: "Hi, I lost this bottle and would like to claim.", isFromUser: true, isImage: false),
    ChatMessage(id: UUID(), text: "Sure!", isFromUser: false, isImage: false),
    ChatMessage(id: UUID(), text: "You can pick it up at the campus police station", isFromUser: false, isImage: false),
    ChatMessage(id: UUID(), text: "Thanks", isFromUser: true, isImage: false),
    ChatMessage(id: UUID(), text: "Welcome", isFromUser: false, isImage: false)
]
