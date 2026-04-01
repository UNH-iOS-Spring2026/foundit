//
//  LocationPickerView.swift
//  foundit
//
//  Created by Divya Panthi on 24/03/2026.
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
 
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var locationText: String
    @Environment(\.dismiss) private var dismiss
 
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.3083, longitude: -72.9279),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var pinCoordinate: CLLocationCoordinate2D? = nil
 
    var body: some View {
        NavigationStack {
            ZStack {
                MapReader { proxy in
                    Map(position: .constant(.region(region))) {
                        if let pin = pinCoordinate {
                            Marker("", coordinate: pin)
                                .tint(Color(red: 0.55, green: 0.60, blue: 0.85))
                        }
                    }
                    .onTapGesture { screenPoint in
                        if let coord = proxy.convert(screenPoint, from: .local) {
                            pinCoordinate = coord
                            region.center = coord
                            reverseGeocode(coord)
                        }
                    }
                }
 
                // ── Hint ───────────────────────────────────────────────
                if pinCoordinate == nil {
                    VStack {
                        Spacer()
                        Text("Tap on the map to drop a pin")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Capsule())
                            .padding(.bottom, 100)
                    }
                }
 
                // ── Confirm Button ─────────────────────────────────────
                if pinCoordinate != nil {
                    VStack {
                        Spacer()
                        Button {
                            selectedCoordinate = pinCoordinate
                            dismiss()
                        } label: {
                            Text("Confirm Location")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.55, green: 0.60, blue: 0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(red: 0.55, green: 0.60, blue: 0.85))
                }
            }
        }
    }
 
    // ── Reverse geocode to get a readable address ──────────────────────
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            if let placemark = placemarks?.first {
                let parts = [
                    placemark.name,
                    placemark.locality,
                    placemark.administrativeArea
                ].compactMap { $0 }
                locationText = parts.joined(separator: ", ")
            }
        }
    }
}

