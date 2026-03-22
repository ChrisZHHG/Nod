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
                .padding(.horizontal, NodTheme.Spacing.xl)
                .padding(.top, NodTheme.Spacing.lg)
                
                Spacer()
                
                // Bottom Bar Controls
                VStack(spacing: NodTheme.Spacing.lg) {
                    // Feedback Text
                    if !images.isEmpty {
                        Text("\(images.count) \(images.count == 1 ? "Photo" : "Photos") captured")
                            .font(.system(size: 14, weight: .light, design: .rounded))
                            .foregroundStyle(.ultraThinMaterial)
                            .shadow(color: .white.opacity(0.2), radius: 3)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)
                            )
                    }

                    HStack(spacing: NodTheme.Spacing.xl) {
                        Spacer()

                        // Capture Button — glass ring with white fill
                        Button(action: {
                            HapticFeedback.light.trigger()
                            shouldCapture = true
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(.white.opacity(0.55), lineWidth: 2.5)
                                    .frame(width: 76, height: 76)
                                Circle()
                                    .fill(.white)
                                    .frame(width: 62, height: 62)
                            }
                        }

                        Spacer()
                    }

                    // Analyze button — amber CTA
                    if !images.isEmpty {
                        Button(action: { onAnalyze() }) {
                            HStack(spacing: 10) {
                                Text("Next")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(NodTheme.Cinematic.deepBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(NodTheme.Cinematic.amber)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, NodTheme.Spacing.xxl)
                    }
                }
                .padding(.vertical, 20)
                .padding(.bottom, 16)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
    }
}
