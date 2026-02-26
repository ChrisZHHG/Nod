import SwiftUI

struct ScannerView: View {
    let images: [Data]
    let onCapture: (Data) -> Void
    let onAnalyze: () -> Void
    let onCancel: () -> Void
    
    @State private var shouldCapture = false
    @State private var latestScannedImageData: Data? = nil
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Camera Feed Overlay
            CameraScannerView(
                scannedImage: $latestScannedImageData,
                shouldCaptureTrigger: shouldCapture
            )
            .ignoresSafeArea()
            .onChange(of: latestScannedImageData) { _, newImage in
                if let data = newImage {
                    onCapture(data)
                    shouldCapture = false // Reset trigger
                }
            }
            
            // UI Overlay
            VStack {
                // Top Bar
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(.horizontal, AmbrosiaTheme.Spacing.xl)
                .padding(.top, AmbrosiaTheme.Spacing.lg)
                
                Spacer()
                
                // Bottom Bar Controls
                VStack(spacing: AmbrosiaTheme.Spacing.lg) {
                    // Feedback Text
                    if !images.isEmpty {
                        Text("\(images.count) Images Captured")
                            .font(AmbrosiaTheme.Typography.subheadline)
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    
                    HStack(spacing: AmbrosiaTheme.Spacing.xl) {
                        Spacer()
                        
                        // Capture Button
                        Button(action: {
                            HapticFeedback.light.trigger()
                            shouldCapture = true
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                                    .frame(width: 72, height: 72)
                                
                                Circle()
                                    .fill(.white)
                                    .frame(width: 60, height: 60)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Finish / Analyze Button
                    if !images.isEmpty {
                        GlassButton(title: "Analyze Menu", icon: "sparkles", variant: .primary) {
                            onAnalyze()
                        }
                        .padding(.horizontal, AmbrosiaTheme.Spacing.xxl)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}
