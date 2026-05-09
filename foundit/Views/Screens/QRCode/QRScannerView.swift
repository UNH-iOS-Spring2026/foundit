//
//  QRScannerView.swift
//  foundit
//
//  Full-screen camera scanner for the claim flow. Uses AVFoundation to
//  read QR codes and presents a result sheet that verifies + redeems
//  the scanned code against Firestore.
//

import SwiftUI
import AVFoundation

// MARK: - Scanner Screen

struct QRScannerView: View {
    /// When non-empty, the scanned token's postId must match this value.
    /// Scoping the scanner to one post blocks scanning a code meant for a different item.
    let claimPostId: String
    /// Called after a successful claim. The parent uses the chatId to push the
    /// student into the chat thread as the shared confirmation surface.
    let onClaimed: (_ chatId: String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var isTorchOn = false
    @State private var showResultSheet = false

    init(claimPostId: String = "", onClaimed: @escaping (String?) -> Void = { _ in }) {
        self.claimPostId = claimPostId
        self.onClaimed = onClaimed
    }

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
            QRResultSheet(code: scannedCode ?? "", expectedPostId: claimPostId) { chatId in
                showResultSheet = false
                onClaimed(chatId)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Scan Result Sheet

/// Three states the result sheet moves through:
/// `verifying` on appear → `success` or `failure` once Firestore responds.
enum QRRedemptionState {
    case verifying
    case success(at: Date, chatId: String?)
    case failure(message: String)
}

/// Sheet shown after the camera reads a QR. Runs verification on `.task`,
/// then renders a confirmation UI or a specific error.
struct QRResultSheet: View {
    /// The raw string the scanner read from the QR.
    let code: String
    /// When non-empty, the scanned token's postId must match this value —
    /// rejects codes that belong to a different post.
    let expectedPostId: String
    /// Called when the user taps Done/Open Chat on the success screen.
    /// Receives the chatId to navigate to, if any.
    let onCompleted: (_ chatId: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var state: QRRedemptionState = .verifying

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            switch state {
            case .verifying:
                verifyingView
            case .success(let when, let chatId):
                successView(returnedAt: when, chatId: chatId)
            case .failure(let message):
                failureView(message: message)
            }

            Spacer()
        }
        .task { await verifyAndRedeem() }
    }

    private var verifyingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.4)
            Text("Verifying claim code…")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
        }
    }

    private func successView(returnedAt: Date, chatId: String?) -> some View {
        VStack(spacing: 0) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Spacer().frame(height: 16)

            Text("Item Returned")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)

            Spacer().frame(height: 8)

            Text(chatId == nil
                 ? "The return has been logged."
                 : "Opening your chat with the police…")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer().frame(height: 24)

            VStack(alignment: .leading, spacing: 12) {
                metaRow(icon: "clock",
                        label: "Time",
                        value: formatted(returnedAt))
                metaRow(icon: "number",
                        label: "Reference",
                        value: String(code.suffix(12)))
            }
            .padding(16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 28)

            Spacer().frame(height: 32)

            Button { onCompleted(chatId) } label: {
                Text(chatId == nil ? "DONE" : "OPEN CHAT")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 28)
        }
    }

    private func failureView(message: String) -> some View {
        VStack(spacing: 0) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 56))
                .foregroundColor(.red)

            Spacer().frame(height: 16)

            Text("Couldn't Verify Code")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)

            Spacer().frame(height: 8)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer().frame(height: 32)

            Button(action: { dismiss() }) {
                Text("Try Again")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(FounditColors.primary))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 28)
        }
    }

    private func metaRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    /// The verification + redemption pipeline. Runs on sheet appear.
    /// Each step can short-circuit with a specific error the UI shows directly.
    ///   1. Parse the scanned string into a nonce.
    ///   2. Look up the token in Firestore.
    ///   3. Check the token belongs to the expected post (if scoped).
    ///   4. Check it hasn't already been consumed or expired.
    ///   5. Redeem it atomically — flips item to returned and closes the chat.
    private func verifyAndRedeem() async {
        // 1. Parse
        guard let nonce = ClaimTokenService.parseNonce(from: code) else {
            state = .failure(message: ClaimTokenError.invalidPayload.errorDescription ?? "Invalid code.")
            return
        }

        let service = ClaimTokenService()
        do {
            // 2. Fetch
            let token = try await service.fetchToken(nonce: nonce)
            // 3. Post-id guard
            if !expectedPostId.isEmpty && token.postId != expectedPostId {
                state = .failure(message: "This code is for a different item.")
                return
            }
            // 4. Freshness checks
            if token.isConsumed { throw ClaimTokenError.alreadyConsumed }
            if token.isExpired  { throw ClaimTokenError.expired }

            // 5. Atomic redemption
            let chatId = try await service.redeemToken(
                token,
                consumedByUserId: AppConfig.currentUserId
            )
            state = .success(at: Date(), chatId: chatId)
        } catch let err as ClaimTokenError {
            state = .failure(message: err.errorDescription ?? "Verification failed.")
        } catch {
            state = .failure(message: error.localizedDescription)
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
