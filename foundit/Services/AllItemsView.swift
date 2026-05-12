//
//  AllItemsView.swift
//  foundit
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Quick Date Filter
private enum QuickDateFilter: String, CaseIterable {
    case thisWeek  = "This Week"
    case lastWeek  = "Last Week"
    case lastMonth = "Last Month"

    var dateRange: (from: Date, to: Date) {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .thisWeek:
            let start = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (start, now)
        case .lastWeek:
            let lastWeekDay = cal.date(byAdding: .weekOfYear, value: -1, to: now)!
            let start = cal.dateInterval(of: .weekOfYear, for: lastWeekDay)?.start ?? lastWeekDay
            let end   = cal.dateInterval(of: .weekOfYear, for: lastWeekDay)?.end   ?? now
            return (start, end)
        case .lastMonth:
            let lastMonthDay = cal.date(byAdding: .month, value: -1, to: now)!
            let start = cal.dateInterval(of: .month, for: lastMonthDay)?.start ?? lastMonthDay
            let end   = cal.dateInterval(of: .month, for: lastMonthDay)?.end   ?? now
            return (start, end)
        }
    }
}

struct AllItemsView: View {
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()

    @State private var selectedType: PostType?             = nil
    @State private var selectedCategory: String?           = nil
    @State private var selectedQuickDate: QuickDateFilter? = nil
    @State private var isCustomRange: Bool                 = false
    @State private var customFromDate: Date                = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customToDate: Date                  = Date()
    @State private var showFilterSheet                     = false

    private let categories = ["Books", "Electronics", "Accessories",
                               "Clothing", "Keys", "Wallet", "Other"]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var hasDateFilter: Bool { selectedQuickDate != nil || isCustomRange }

    private var activeFilterCount: Int {
        var n = 0
        if selectedType     != nil { n += 1 }
        if selectedCategory != nil { n += 1 }
        if hasDateFilter           { n += 1 }
        return n
    }

    private var activeDateRangeLabel: String {
        if let q = selectedQuickDate { return q.rawValue }
        if isCustomRange             { return "Custom Range" }
        return ""
    }

    var filteredItems: [Post] {
        var items = viewModel.filteredItems

        if let type = selectedType {
            items = items.filter { $0.type == type }
        }
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        if let quick = selectedQuickDate {
            let (from, to) = quick.dateRange
            items = items.filter {
                let d = $0.createdAt.dateValue()
                return d >= from && d <= to
            }
        } else if isCustomRange {
            let to = Calendar.current.date(byAdding: .day, value: 1, to: customToDate) ?? customToDate
            items = items.filter {
                let d = $0.createdAt.dateValue()
                return d >= customFromDate && d <= to
            }
        }
        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Search + Filter button ─────────────────────────────
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search items…", text: $viewModel.searchText)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(Capsule())

                Button { showFilterSheet = true } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(activeFilterCount > 0
                                ? Color(red: 0.55, green: 0.60, blue: 0.85) : .secondary)
                            .frame(width: 36, height: 36)
                            .background(activeFilterCount > 0
                                ? Color(red: 0.55, green: 0.60, blue: 0.85).opacity(0.12)
                                : Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        if activeFilterCount > 0 {
                            Text("\(activeFilterCount)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 14, height: 14)
                                .background(Color(red: 0.55, green: 0.60, blue: 0.85))
                                .clipShape(Circle())
                                .offset(x: 5, y: -5)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            // ── Active filter chips ────────────────────────────────
            if activeFilterCount > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let type = selectedType {
                            ActiveFilterChip(label: type.label) { selectedType = nil }
                        }
                        if let cat = selectedCategory {
                            ActiveFilterChip(label: cat) { selectedCategory = nil }
                        }
                        if hasDateFilter {
                            ActiveFilterChip(label: activeDateRangeLabel) {
                                selectedQuickDate = nil
                                isCustomRange = false
                            }
                        }
                        Button {
                            selectedType = nil; selectedCategory = nil
                            selectedQuickDate = nil; isCustomRange = false
                        } label: {
                            Text("Clear All")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
            }

            Divider()

            // ── Items Grid ────────────────────────────────────────
            ScrollView {
                if viewModel.isLoading {
                    ProgressView().padding(.top, 60)
                } else if filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No items found")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Try adjusting your filters or search")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredItems) { item in
                            NavigationLink {
                                PostDetailView(item: item, chatViewModel: chatViewModel)
                            } label: {
                                ItemCardView(
                                    item: item,
                                    onDelete: nil, onEdit: nil,
                                    canDelete: item.createdBy == authVM.currentUser?.uid,
                                    canEdit:   item.createdBy == authVM.currentUser?.uid
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("All Items")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showFilterSheet) {
            AllItemsFilterSheet(
                selectedType:      $selectedType,
                selectedCategory:  $selectedCategory,
                selectedQuickDate: $selectedQuickDate,
                isCustomRange:     $isCustomRange,
                customFromDate:    $customFromDate,
                customToDate:      $customToDate,
                categories:        categories
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Active Filter Chip
private struct ActiveFilterChip: View {
    let label: String
    let onRemove: () -> Void
    var body: some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 12, weight: .medium))
            Button(action: onRemove) {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundStyle(Color(red: 0.55, green: 0.60, blue: 0.85))
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Color(red: 0.55, green: 0.60, blue: 0.85).opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Filter Sheet
private struct AllItemsFilterSheet: View {
    @Binding var selectedType: PostType?
    @Binding var selectedCategory: String?
    @Binding var selectedQuickDate: QuickDateFilter?
    @Binding var isCustomRange: Bool
    @Binding var customFromDate: Date
    @Binding var customToDate: Date
    let categories: [String]

    @Environment(\.dismiss) private var dismiss

    private let accent = Color(red: 0.55, green: 0.60, blue: 0.85)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Type ────────────────────────────────────────
                    section("Type") {
                        HStack(spacing: 10) {
                            chip("All",   isSelected: selectedType == nil)    { selectedType = nil }
                            chip("Lost",  isSelected: selectedType == .lost)  { selectedType = .lost }
                            chip("Found", isSelected: selectedType == .found) { selectedType = .found }
                        }
                    }

                    // ── Category ────────────────────────────────────
                    section("Category") {
                        let allItems = ["All"] + categories  // 8 items total
                        let row1 = Array(allItems.prefix(4))
                        let row2 = Array(allItems.dropFirst(4))
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                ForEach(row1, id: \.self) { label in
                                    categoryChip(label)
                                }
                            }
                            HStack(spacing: 10) {
                                ForEach(row2, id: \.self) { label in
                                    categoryChip(label)
                                }
                                // Pad remaining space so chips don't stretch
                                Spacer()
                            }
                        }
                    }

                    // ── Date ────────────────────────────────────────
                    section("Date") {
                        VStack(spacing: 10) {
                            // Quick options — equal-width buttons
                            HStack(spacing: 8) {
                                ForEach(QuickDateFilter.allCases, id: \.self) { option in
                                    Button {
                                        if selectedQuickDate == option {
                                            selectedQuickDate = nil
                                        } else {
                                            selectedQuickDate = option
                                            isCustomRange = false
                                        }
                                    } label: {
                                        Text(option.rawValue)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(selectedQuickDate == option ? .white : .primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                selectedQuickDate == option
                                                    ? accent : Color(.systemGray6)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }

                            // Custom range toggle row
                            Button {
                                isCustomRange.toggle()
                                if isCustomRange { selectedQuickDate = nil }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: isCustomRange
                                          ? "calendar.badge.checkmark" : "calendar")
                                        .font(.system(size: 15))
                                        .foregroundStyle(isCustomRange ? accent : .secondary)
                                    Text("Custom date range")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: isCustomRange ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    isCustomRange
                                        ? accent.opacity(0.08)
                                        : Color(.systemGray6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isCustomRange ? accent.opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            // Inline date pickers
                            if isCustomRange {
                                VStack(spacing: 0) {
                                    dateRow(label: "From", date: $customFromDate,
                                            range: Date.distantPast...customToDate)
                                    Divider().padding(.horizontal, 16)
                                    dateRow(label: "To",   date: $customToDate,
                                            range: customFromDate...Date())
                                }
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(accent.opacity(0.4), lineWidth: 1)
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: isCustomRange)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        selectedType = nil; selectedCategory = nil
                        selectedQuickDate = nil; isCustomRange = false
                        customFromDate = Calendar.current.date(
                            byAdding: .month, value: -1, to: Date()) ?? Date()
                        customToDate = Date()
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(accent)
                }
            }
        }
    }

    // MARK: - Helpers
    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            content()
        }
    }

    private func categoryChip(_ label: String) -> some View {
        let isSelected = label == "All" ? selectedCategory == nil : selectedCategory == label
        return Button {
            selectedCategory = label == "All" ? nil : label
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(isSelected ? accent : Color(.systemGray6))
                .clipShape(Capsule())
        }
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(isSelected ? accent : Color(.systemGray6))
                .clipShape(Capsule())
        }
    }

    private func dateRow(label: String, date: Binding<Date>, range: ClosedRange<Date>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
            DatePicker("", selection: date, in: range, displayedComponents: .date)
                .labelsHidden()
                .tint(accent)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Filter Chip (used in HomeView)
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(
                    isSelected
                        ? Color(red: 0.55, green: 0.60, blue: 0.85)
                        : Color(.systemGray6)
                )
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview
#Preview {
    AllItemsView()
        .environmentObject(PostViewModel())
        .environmentObject(ChatViewModel())
        .environmentObject(AuthViewModel())
}
