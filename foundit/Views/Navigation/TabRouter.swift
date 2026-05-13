import SwiftUI
import Combine

enum AppTab: Hashable {
    case home
    case chat
    case myPosts
    case profile
}

@MainActor
final class TabRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
    // Set to a postId to trigger deep-link navigation to PostDetailView
    @Published var pendingPostId: String?
}
