//
//  HomeHeaderView.swift
//  foundit
//
//  Created by Divya Panthi on 17/03/2026.
//

import SwiftUI

struct HomeHeaderView: View {

    let userName: String
    let userEmail: String
    let unreadCount: Int
    var avatarUrl: String? = nil
    var onPost: () -> Void = {}
    var onNotificationTap: () -> Void = {}
    var onProfileTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Button(action: onProfileTap) {
                    HStack(spacing: 10) {
                        Group {
                            if let urlString = avatarUrl, let url = URL(string: urlString) {
                                CachedAsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().scaledToFill()
                                    default:
                                        Image(systemName: "person.fill")
                                            .foregroundStyle(.white)
                                    }
                                }
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundStyle(.white)
                                    )
                            }
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(userName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                            Text(userEmail)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Notification bell
                Button(action: onNotificationTap) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: unreadCount > 0 ? "bell.fill" : "bell")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)

                        if unreadCount > 0 {
                            ZStack {
                                Capsule()
                                    .fill(Color.red)
                                    .frame(
                                        width: unreadCount > 9 ? 22 : 16,
                                        height: 16
                                    )
                                Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: unreadCount > 9 ? 10 : 7, y: -7)
                        }
                    }
                }
            }
            
            // Banner
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lost or found an item?")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("You can post it here\nfor easy recovery")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onPost) {
                    Text("Post")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(FounditColors.primary))
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Color(FounditColors.primary))
    }
    
}
