//
//  HomeViewModel.swift
//  foundit
//
//  Created by Divya Panthi on 17/03/2026.
//

import Foundation
import Combine
 

final class HomeViewModel: ObservableObject {
 
    // MARK: Published State
    @Published var items: [LostFoundItem] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
 
    // MARK: filtered items
    var filteredItems: [LostFoundItem] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return items
        }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
 
    // MARK: Init
    init() {
        loadItems()
    }
 
    // MARK: Load (replace with real API/repo call)
    func loadItems() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.items = LostFoundItem.mockItems
            self?.isLoading = false
        }
    }
}
 
