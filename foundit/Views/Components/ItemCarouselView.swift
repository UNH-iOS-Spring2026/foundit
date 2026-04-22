//
//  ItemCarouselView.swift
//  foundit
//
//  Created by Divya Panthi on 24/03/2026.
//

import SwiftUI

// MARK: ItemImageCarouselView
// Swipeable image carousel with page indicator dots and arrow hint.
struct ItemImageCarouselView: View {

    let images: [String]
    @State private var currentIndex: Int = 0

    var body: some View {
        if images.isEmpty {
            ZStack {
                Color(.systemGray5)
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(.systemGray3))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            carouselContent
        }
    }

    private var carouselContent: some View {
        ZStack(alignment: .bottomTrailing) {

            // ── Paging TabView
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageName in
                    carouselImage(for: imageName)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity)
            .frame(height: 260)

            // ── Page Dots
            if images.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                            .frame(width: index == currentIndex ? 8 : 6,
                                   height: index == currentIndex ? 8 : 6)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.3))
                .clipShape(Capsule())
                .padding(12)
            }

            // ── Arrow hint (right edge)
            if images.count > 1 && currentIndex < images.count - 1 {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
                    .padding(.trailing, 12)
                    .padding(.bottom, 40)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: – Single image
    @ViewBuilder
    private func carouselImage(for imageName: String) -> some View {
        if let url = URL(string: imageName), url.scheme == "https" || url.scheme == "http" {
            CachedAsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipped()
                case .failure:
                    imagePlaceholder
                default:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .background(Color(.systemGray6))
                }
            }
        } else {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipped()
        }
    }

    private var imagePlaceholder: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundStyle(Color(.systemGray3))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
    }
}

#Preview {
    ItemImageCarouselView(images: ["charger", "glasses"])
        .padding()
}

