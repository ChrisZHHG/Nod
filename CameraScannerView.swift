import SwiftUI
import VisionKit

// MARK: - Real Camera (VisionKit)

@MainActor
struct CameraScannerView: UIViewControllerRepresentable {
    // Basic Bindings
    @Binding var scannedImage: Data?
    var shouldCaptureTrigger: Bool // Toggled by parent to trigger capture
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .high,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
        
        // Trigger verification
        if shouldCaptureTrigger {
            Task {
                if let image = try? await uiViewController.capturePhoto() {
                    // Compress and return
                    context.coordinator.parent.scannedImage = image.jpegData(compressionQuality: 0.8)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: CameraScannerView
        weak var scanner: DataScannerViewController?
        
        init(_ parent: CameraScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            // Optional: User tapped specific text
        }
    }
}

