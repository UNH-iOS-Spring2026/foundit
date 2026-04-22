//
//  QRCodeDrawerView.swift
//  foundit
//
//  Bottom-sheet shown to the police when they tap "Show QR Code".
//  Renders a QR image from the given string, shows a live countdown
//  until the code expires, and exposes Copy / Share actions.
//

import SwiftUI
import Combine
import CoreImage.CIFilterBuiltins

// MARK: - QR Code Drawer (Bottom Sheet)

struct QRCodeDrawerView: View {
    /// The string to encode into the QR image (the `foundit-claim://…` URL).
    let itemCode: String
    /// Item title shown in the drawer header.
    let itemTitle: String
    /// When set, the drawer shows a live countdown and greys the QR out on expiry.
    let expiresAt: Date?
    /// Optional demo hook. When non-nil, a "Simulate Student Scan" button is shown.
    let onSimulateClaim: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    /// Updated every second by `ticker` so the countdown label refreshes.
    @State private var now: Date = Date()
    @State private var isSimulating = false

    /// Drives the countdown — emits every second while the drawer is visible.
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        itemCode: String,
        itemTitle: String,
        expiresAt: Date? = nil,
        onSimulateClaim: (() -> Void)? = nil
    ) {
        self.itemCode = itemCode
        self.itemTitle = itemTitle
        self.expiresAt = expiresAt
        self.onSimulateClaim = onSimulateClaim
    }

    /// Seconds left before `expiresAt`. Zero if unset or already past.
    private var remaining: TimeInterval {
        guard let expiresAt else { return 0 }
        return max(0, expiresAt.timeIntervalSince(now))
    }

    /// True once the TTL has lapsed — used to grey the QR out.
    private var isExpired: Bool {
        expiresAt != nil && remaining <= 0
    }

    /// Formatted "Expires in M:SS" text for the drawer header.
    private var countdownText: String {
        let total = Int(remaining)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "Expires in %d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Item QR Code")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    Text(itemTitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    if expiresAt != nil {
                        Text(isExpired ? "Code expired" : countdownText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isExpired ? .red : .orange)
                            .padding(.top, 2)
                    }
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 32)

            // QR Code
            if let qrImage = generateQRCode(from: itemCode) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                    .opacity(isExpired ? 0.4 : 1.0)
                    .overlay {
                        if isExpired {
                            Text("Code expired — close and reopen\nto regenerate.")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(10)
                                .background(Color.white.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
            }

            Spacer().frame(height: 16)

            // Item code label
            Text(itemCode)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(.black.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(Capsule())

            Spacer().frame(height: 32)

            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    UIPasteboard.general.string = itemCode
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 15))
                        Text("Copy Code")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.black.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                ShareLink(item: itemCode) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15))
                        Text("Share")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(FounditColors.primary))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 28)

            if let onSimulateClaim {
                Spacer().frame(height: 16)

                Button {
                    guard !isSimulating else { return }
                    isSimulating = true
                    onSimulateClaim()
                } label: {
                    HStack(spacing: 8) {
                        if isSimulating {
                            ProgressView().tint(.orange)
                        } else {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 14))
                        }
                        Text(isSimulating ? "Simulating…" : "Simulate Student Scan")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.orange.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.orange.opacity(0.35),
                                          style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSimulating || isExpired)
                .padding(.horizontal, 28)

                Text("Demo only — redeems the code as if the student scanned it.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 28)
                    .padding(.top, 6)
            }

            Spacer()
        }
        .onReceive(ticker) { tick in
            guard expiresAt != nil else { return }
            now = tick
        }
        .onAppear { now = Date() }
    }

    /// Turns the given string into a UIImage of a QR code using Core Image.
    /// Scaled up 10x so the code stays crisp when drawn at 220×220 points.
    private func generateQRCode(from string: String) -> UIImage? {
        guard !string.isEmpty else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"   // medium error correction — good for screen-to-camera

        guard let outputImage = filter.outputImage else { return nil }

        // Native CIImage output is tiny; scale up so pixels aren't blurry.
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        let extent = scaledImage.extent
        guard extent.width > 0, extent.height > 0, extent.width.isFinite, extent.height.isFinite else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Preview

#Preview {
    QRCodeDrawerView(itemCode: "FOUNDIT-ITM-00342", itemTitle: "Grey Water Bottle")
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
