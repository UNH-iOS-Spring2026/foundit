import SwiftUI

enum AppTab: Hashable {
    case home
    case report
    case chat
    case profile
}

@MainActor
final class TabRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
}

