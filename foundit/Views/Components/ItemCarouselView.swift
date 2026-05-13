//
//  ItemCarouselView.swift
//  foundit
//
//  Created by Divya Panthi on 24/03/2026.
//

import SwiftUI

// MARK: ItemImageCarouselView
// Swipeable image carousel with page indicator dots and tap-to-fullscreen.
struct ItemImageCarouselView: View {

    let images: [String]
    @State private var currentIndex: Int = 0
    @State private var showFullScreen = false

    var body: some View {
        if images.isEmpty {
            Image("default_item_image")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            carouselContent
                .fullScreenCover(isPresented: $showFullScreen) {
                    FullScreenImageViewer(images: images, initialIndex: currentIndex)
                }
        }
    }

    private var carouselContent: some View {
        ZStack(alignment: .bottomTrailing) {

            // ── Paging TabView
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageName in
                    carouselImage(for: imageName)
                        .tag(index)
                        .onTapGesture {
                            currentIndex = index
                            showFullScreen = true
                        }
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
        Image("default_item_image")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .clipped()
    }
}

// MARK: - Full Screen Image Viewer
struct FullScreenImageViewer: View {
    let images: [String]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int

    init(images: [String], initialIndex: Int) {
        self.images = images
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            // ── Swipeable full-screen images
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageName in
                    fullImage(for: imageName)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // ── Page counter (e.g. "2 / 5")
            if images.count > 1 {
                Text("\(currentIndex + 1) / \(images.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity)
                    .padding(.top, 56)
            }

            // ── Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            .padding(.top, 56)
            .padding(.trailing, 20)
        }
    }

    @ViewBuilder
    private func fullImage(for imageName: String) -> some View {
        if let url = URL(string: imageName), url.scheme == "https" || url.scheme == "http" {
            CachedAsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failure:
                    Image("default_item_image")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                default:
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        } else {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ItemImageCarouselView(images: ["charger", "glasses"])
        .padding()
}

