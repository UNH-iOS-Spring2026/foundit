//
//  PostDetailView.swift
//  foundit
//
//  Created by Divya Panthi on 24/03/2026.
//

import SwiftUI
import MapKit

struct PostDetailView: View {
    let item: LostFoundItem
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                
                ItemImageCarouselView(images: item.images)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                VStack(alignment: .leading, spacing: 8) {
                    
                    Text(item.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text(item.category)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Text(item.formattedDate)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Text(item.formattedTime)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Reported by")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 10) {
                        if UIImage(named: item.reportedBy.avatarName) != nil {
                            Image(item.reportedBy.avatarName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(.systemGray4))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(Color(.systemGray))
                                )
                        }
                        
                        Text(item.reportedBy.name)
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(item.description)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Location")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    // Map
                    Map(position: .constant(
                        .region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(
                                    latitude: item.coordinate.latitude,
                                    longitude: item.coordinate.longitude
                                ),
                                span: MKCoordinateSpan(
                                    latitudeDelta: 0.05,
                                    longitudeDelta: 0.05
                                )
                            )
                        )
                    )) {
                        Marker("", coordinate: CLLocationCoordinate2D(
                            latitude: item.coordinate.latitude,
                            longitude: item.coordinate.longitude
                        ))
                        .tint(Color(red: 0.55, green: 0.60, blue: 0.85))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(true)   // non-interactive, tap to open Maps if needed
                    
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.pink)
                            .font(.system(size: 16))
                        Text(item.location)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                
                Button {
                       // TODO: handle action
                   } label: {
                       Text("Take Action")
                           .font(.system(size: 16, weight: .semibold))
                           .foregroundStyle(.white)
                           .frame(maxWidth: .infinity)
                           .padding(.vertical, 16)
                           .background(Color(red: 0.55, green: 0.60, blue: 0.85))
                           .clipShape(RoundedRectangle(cornerRadius: 14))
                   }
                   .padding(.horizontal, 16)
                   .padding(.top, 24)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Similar Items")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
 
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(LostFoundItem.mockItems) { similarItem in
                            NavigationLink {
                                PostDetailView(item: similarItem)
                            } label: {
                                ItemCardView(item: similarItem)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
                
            }
        }
        .navigationTitle("Report Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PostDetailView(item: LostFoundItem.mockItems[0])
    }
}
