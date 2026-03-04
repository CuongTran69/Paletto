import SwiftUI
import AVFoundation

/// Camera preview that samples the center pixel color each frame
struct CameraPreviewView: UIViewRepresentable {
    let onColorSampled: (CGFloat, CGFloat, CGFloat) -> Void
    var isActive: Bool

    func makeUIView(context: Context) -> CameraUIView {
        let view = CameraUIView()
        view.onColorSampled = onColorSampled
        return view
    }

    func updateUIView(_ uiView: CameraUIView, context: Context) {
        if isActive {
            uiView.startSession()
        } else {
            uiView.stopSession()
        }
    }

    static func dismantleUIView(_ uiView: CameraUIView, coordinator: ()) {
        uiView.stopSession()
    }
}

/// UIView hosting AVCaptureSession with video output for color sampling
final class CameraUIView: UIView {
    var onColorSampled: ((CGFloat, CGFloat, CGFloat) -> Void)?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.paletto.camera")
    private let sampleDelegate = SampleDelegate()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSession()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSession()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let session = self?.captureSession, session.isRunning else { return }
            session.stopRunning()
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let session = self?.captureSession, !session.isRunning else { return }
            session.startRunning()
        }
    }

    private func setupSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .medium

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }

        session.addInput(input)

        videoOutput.setSampleBufferDelegate(sampleDelegate, queue: sessionQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = bounds
        layer.addSublayer(preview)

        self.captureSession = session
        self.previewLayer = preview

        sampleDelegate.onColorSampled = { [weak self] r, g, b in
            DispatchQueue.main.async {
                self?.onColorSampled?(r, g, b)
            }
        }

        sessionQueue.async {
            session.startRunning()
        }
    }
}

/// Delegate that reads the center pixel from each video frame
private final class SampleDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onColorSampled: ((CGFloat, CGFloat, CGFloat) -> Void)?
    private var frameCount: Int = 0
    private let sampleInterval = 5
    private let colorThreshold: CGFloat = 0.01 // ~2.5/255 — skip if delta < this
    private var lastR: CGFloat = -1
    private var lastG: CGFloat = -1
    private var lastB: CGFloat = -1

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Sample every Nth frame for performance
        frameCount += 1
        guard frameCount >= sampleInterval else { return }
        frameCount = 0

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }

        let centerX = width / 2
        let centerY = height / 2
        let offset = centerY * bytesPerRow + centerX * 4

        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let b = CGFloat(pointer[offset]) / 255.0
        let g = CGFloat(pointer[offset + 1]) / 255.0
        let r = CGFloat(pointer[offset + 2]) / 255.0

        // Skip if color hasn't changed significantly — avoids unnecessary main thread dispatches
        guard abs(r - lastR) > colorThreshold ||
              abs(g - lastG) > colorThreshold ||
              abs(b - lastB) > colorThreshold else { return }

        lastR = r
        lastG = g
        lastB = b

        onColorSampled?(r, g, b)
    }
}

