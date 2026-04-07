//
//  ItemCardView.swift
//  foundit
//
//  Created by Divya Panthi on 17/03/2026.
//

import SwiftUI

struct ItemCardView: View {

    let item: Post
    var onDelete: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var canDelete: Bool = false
    var canEdit: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            ZStack(alignment: .topTrailing) {
                itemImage
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)
                    .clipped()

                StatusBadgeView(type: item.type)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(item.formattedDate)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.pink)
                        .font(.system(size: 13))
                    Text(item.lastSeenLocationText)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
        .contextMenu {
            if canEdit {
                Button {
                    onEdit?()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            if canDelete {
                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    // MARK: – Image resolution
    @ViewBuilder
    private var itemImage: some View {
        if let urlString = item.primaryImageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 130)
                        .clipped()
                case .failure:
                    placeholderImage
                default:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray6))
                }
            }
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "photo")
                .font(.system(size: 36))
                .foregroundStyle(Color(.systemGray2))
        }
    }
}

// MARK: - StatusBadgeView
struct StatusBadgeView: View {

    let type: PostType

    private var badgeColor: Color {
        switch type {
        case .lost:  return .pink
        case .found: return .green
        }
    }

    var body: some View {
        Text(type.label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(badgeColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.white)
            .clipShape(Capsule())
    }
}

//#Preview {
//    ItemCardView()
//}
