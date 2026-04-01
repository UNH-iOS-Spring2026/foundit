//
//  QRScannerView.swift
//  foundit
//

import SwiftUI
import AVFoundation

// MARK: - Scanner Screen

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var isTorchOn = false
    @State private var showResultSheet = false

    var body: some View {
        ZStack {
            // Camera feed
            QRCameraPreview(scannedCode: $scannedCode, isTorchOn: $isTorchOn)
                .ignoresSafeArea()

            // Overlay
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("Scan QR Code")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { isTorchOn.toggle() }) {
                        Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Scanner frame
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(FounditColors.primary), lineWidth: 3)
                        .frame(width: 260, height: 260)

                    // Corner accents
                    ScannerCornersShape()
                        .stroke(Color(FounditColors.primary), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 260, height: 260)
                }

                Spacer()

                // Bottom hint
                Text("Point your camera at a QR code on the item tag")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 50)
            }
        }
        .onChange(of: scannedCode) { _, newValue in
            if newValue != nil {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                showResultSheet = true
            }
        }
        .sheet(isPresented: $showResultSheet, onDismiss: {
            scannedCode = nil
        }) {
            QRResultSheet(code: scannedCode ?? "")
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Scan Result Sheet

struct QRResultSheet: View {
    let code: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.green)

            Spacer().frame(height: 16)

            Text("QR Code Scanned")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)

            Spacer().frame(height: 8)

            Text("Item identified successfully")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            Spacer().frame(height: 24)

            // Code display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Item Code")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Text(code)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
                Spacer()
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 28)

            Spacer().frame(height: 24)

            Button(action: { dismiss() }) {
                Text("VIEW ITEM DETAILS")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(FounditColors.primary))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 12)

            Button(action: { dismiss() }) {
                Text("Scan Another")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }
}

// MARK: - Scanner Corner Accents

struct ScannerCornersShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerLength: CGFloat = 40
        let cornerRadius: CGFloat = 24
        var path = Path()

        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
                          control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.minY))

        // Top-right
        path.move(to: CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLength))

        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))

        // Bottom-left
        path.move(to: CGPoint(x: rect.minX + cornerLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius),
                          control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLength))

        return path
    }
}

// MARK: - Camera Preview (AVFoundation)

struct QRCameraPreview: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isTorchOn: Bool

    func makeUIViewController(context: Context) -> QRScannerController {
        let controller = QRScannerController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerController, context: Context) {
        uiViewController.setTorch(on: isTorchOn)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode)
    }

    class Coordinator: NSObject, QRScannerControllerDelegate {
        @Binding var scannedCode: String?

        init(scannedCode: Binding<String?>) {
            _scannedCode = scannedCode
        }

        func didFindCode(_ code: String) {
            scannedCode = code
        }
    }
}

// MARK: - AVFoundation Scanner Controller

protocol QRScannerControllerDelegate: AnyObject {
    func didFindCode(_ code: String)
}

class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerControllerDelegate?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isProcessing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)

        self.captureSession = session
        self.previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !isProcessing,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue else { return }

        isProcessing = true
        captureSession?.stopRunning()
        delegate?.didFindCode(code)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isProcessing = false
            self?.captureSession?.startRunning()
        }
    }
}

// MARK: - Preview

#Preview {
    QRScannerView()
}
