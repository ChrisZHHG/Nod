import SwiftUI
import VisionKit

// MARK: - Real Camera (VisionKit)

@MainActor
struct CameraScannerView: UIViewControllerRepresentable {
    @Binding var scannedImage: Data?
    var shouldCaptureTrigger: Bool

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.parent = self

        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }

        // Rising-edge detection: only fire when shouldCaptureTrigger transitions
        // from false → true. Without this, every SwiftUI re-render that happens
        // while the Bool is still `true` would spawn another capturePhoto() Task,
        // causing duplicate photos.
        let wasTriggered = context.coordinator.lastTriggerState
        context.coordinator.lastTriggerState = shouldCaptureTrigger

        guard shouldCaptureTrigger, !wasTriggered, !context.coordinator.isCaptureInFlight else { return }
        context.coordinator.isCaptureInFlight = true

        Task {
            defer { context.coordinator.isCaptureInFlight = false }
            if let image = try? await uiViewController.capturePhoto() {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                context.coordinator.parent.scannedImage = image.jpegData(compressionQuality: 0.8)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: CameraScannerView
        weak var scanner: DataScannerViewController?
        /// Tracks the previous value of shouldCaptureTrigger for rising-edge detection
        var lastTriggerState = false
        /// Prevents concurrent capturePhoto() calls
        var isCaptureInFlight = false

        init(_ parent: CameraScannerView) { self.parent = parent }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {}
    }
}

