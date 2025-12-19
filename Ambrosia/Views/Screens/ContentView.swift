import SwiftUI
import VisionKit

// MARK: - App Entry Point
// (Ideally move to separate file in Refactor step, keeping here for now to ensure compile)
@main
struct AmbrosiaApp: App {
    @StateObject private var manager = AmbrosiaManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
        }
    }
}

// MARK: - Main View (Liquid Glass Style)

struct ContentView: View {
    @EnvironmentObject var manager: AmbrosiaManager
    
    var body: some View {
        ZStack {
            // iOS 26 Liquid Glass Background
            LiquidBackground()
            
            switch manager.state {
            case .idle:
                WelcomeView()
            case .scanning(let images):
                ScannerView(imageCount: images.count)
            case .decoding(let progress):
                ProgressView("Reading Menu...", value: progress, total: 1.0)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
            case .reasoning(let stage):
                ThinkingView(stage: stage)
            case .verifying:
                ThinkingView(stage: "Verifying Safety...")
            case .result(let rec):
                ChefCardView(recommendation: rec)
            case .error(let msg):
                ErrorView(message: msg)
            }
        }
        .animation(.fluidSpring, value: manager.state) // "Silky" Transitions
    }
}

// MARK: - Subviews

struct WelcomeView: View {
    @EnvironmentObject var manager: AmbrosiaManager
    var body: some View {
        VStack {
            Image(systemName: "camera.shutter.button")
                .font(.system(size: 80))
                .foregroundStyle(.linearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .onTapGesture {
                    manager.startSession()
                }
            Text("Tap to Scan Menu")
                .font(.glassTitle)
                .foregroundColor(.white.opacity(0.8))
                .padding(.top)
        }
    }
}

struct ScannerView: View {
    @EnvironmentObject var manager: AmbrosiaManager
    let imageCount: Int
    
    // Trigger State
    @State private var isCapturing = false
    @State private var scannedData: Data? = nil
    
    var body: some View {
        VStack {
            Spacer()
            
            // VisionKit Camera Card
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                ZStack {
                    CameraScannerView(scannedImage: $scannedData, shouldCaptureTrigger: isCapturing)
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .shadow(color: .black.opacity(0.2), radius: 10)
                        .padding()
                        .frame(height: 400) // Fixed height for scanner window
                    
                    if isCapturing {
                        Color.white.opacity(0.3).cornerRadius(24).padding()
                    }
                }
                .onChange(of: scannedData) { newData in
                    if let data = newData {
                        manager.addImage(data)
                        isCapturing = false 
                        scannedData = nil
                    }
                }
            } else {
                Text("Camera Not Available")
                    .foregroundColor(.red)
                    .padding()
                    .glassCard()
            }
            
            // Control Bar
            HStack {
                Text("\(imageCount) Pages")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .glassCard()
                
                Spacer()
                
                Button("Snap") {
                    isCapturing = true
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(isCapturing)
                
                if imageCount > 0 {
                    Button("Done") {
                        Task { await manager.generateRecommendation() }
                    }
                    .buttonStyle(GlassButtonStyle(color: .purple))
                }
            }
            .padding()
        }
    }
}

struct ThinkingView: View {
    let stage: String
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.cyan)
            Text(stage)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top)
        }
        .padding(40)
        .glassCard()
    }
}

struct ChefCardView: View {
    let recommendation: MenuRecommendation
    @EnvironmentObject var manager: AmbrosiaManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image Header
                if let url = recommendation.imageURL {
                    AsyncImage(url: url) { image in
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                             .frame(height: 250)
                             .clipped()
                    } placeholder: {
                        Rectangle().fill(Color.white.opacity(0.1)).frame(height: 250)
                    }
                    .mask(LinearGradient(gradient: Gradient(stops: [
                        .init(color: .black, location: 0.8),
                        .init(color: .clear, location: 1.0)
                    ]), startPoint: .top, endPoint: .bottom))
                }
                
                VStack(spacing: 16) {
                    Text("Chef's Choice")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    
                    Text(recommendation.translation.localizedName)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    Text(recommendation.recommendedItem.originalName)
                        .font(.title3)
                        .italic()
                        .foregroundStyle(.linearGradient(colors: [.cyan, .white], startPoint: .leading, endPoint: .trailing))
                    
                    Divider().background(Color.white.opacity(0.3))
                    
                    Text(recommendation.translation.culturalContext)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(6)
                    
                    // Tags
                    if !recommendation.translation.warnings.isEmpty {
                        HStack {
                            ForEach(recommendation.translation.warnings, id: \.self) { warn in
                                Text(warn)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(8)
                                    .foregroundColor(.pink)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.pink.opacity(0.5), lineWidth: 0.5))
                            }
                        }
                    }
                }
                .padding()
                
                Button {
                    manager.startSession()
                } label: {
                    Text("Start Over")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(GlassButtonStyle())
                .padding()
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .padding()
        .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 15)
    }
}

struct ErrorView: View {
    let message: String
    @EnvironmentObject var manager: AmbrosiaManager
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            Text("Analysis Interrupted")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
            Text(message)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding()
            Button("Try Again") { manager.startSession() }
                .buttonStyle(GlassButtonStyle())
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Design System Helpers

struct GlassButtonStyle: ButtonStyle {
    var color: Color = .white.opacity(0.1)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(color)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension View {
    func glassCard() -> some View {
        self
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
            .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

extension Animation {
    static let fluidSpring = Animation.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.6)
}

extension Font {
    static let glassTitle = Font.system(.body, design: .rounded).weight(.medium)
}
