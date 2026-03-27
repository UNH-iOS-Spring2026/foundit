//
//  QRCodeDrawerView.swift
//  foundit
//

import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - QR Code Drawer (Bottom Sheet)

struct QRCodeDrawerView: View {
    let itemCode: String
    let itemTitle: String
    @Environment(\.dismiss) private var dismiss

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

            Spacer()
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Preview

#Preview {
    QRCodeDrawerView(itemCode: "FOUNDIT-ITM-00342", itemTitle: "Grey Water Bottle")
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
