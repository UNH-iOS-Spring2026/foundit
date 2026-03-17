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
    let hasNotification: Bool
    var onPost: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(userName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(userEmail)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.85))
                }
                
                Spacer()
                
                // Notification bell
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                    
                    if hasNotification {
                        Circle()
                            .fill(.red)
                            .frame(width: 9, height: 9)
                            .offset(x: 2, y: -2)
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
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .overlay(
                            Capsule().stroke(Color(FounditColors.primary), lineWidth: 1.5)
                        )
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Color(red: 0.55, green: 0.60, blue: 0.85))   // periwinkle blue
    }
    
}
#Preview {
//    HomeHeaderView()
}
