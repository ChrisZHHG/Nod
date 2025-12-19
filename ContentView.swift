import SwiftUI

// MARK: - Phase 3: UI & Binding

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

struct ContentView: View {
    @EnvironmentObject var manager: AmbrosiaManager
    
    var body: some View {
        ZStack {
            // Background Layer
            Color.black.edgesIgnoringSafeArea(.all)
            
            switch manager.state {
            case .idle:
                WelcomeView()
            case .scanning(let images):
                ScannerView(imageCount: images.count)
            case .decoding(let progress):
                ProgressView("Reading Menu...", value: progress, total: 1.0)
                    .progressViewStyle(CircularProgressViewStyle(tint: .gold))
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
        .animation(.spring(), value: manager.state) // "Silky" Transitions
    }
}

// MARK: - Subviews

struct WelcomeView: View {
    @EnvironmentObject var manager: AmbrosiaManager
    var body: some View {
        VStack {
            Image(systemName: "camera.shutter.button")
                .font(.system(size: 80))
                .foregroundColor(.white)
                .onTapGesture {
                    manager.startSession()
                }
            Text("Tap to Scan Menu")
                .foregroundColor(.gray)
                .padding(.top)
        }
    }
}

struct ScannerView: View {
    @EnvironmentObject var manager: AmbrosiaManager
    let imageCount: Int
    
    var body: some View {
        VStack {
            Spacer()
            // Placeholder Camera View (Simulator Friendly)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .overlay(Text("Camera Preview").foregroundColor(.white))
                .padding()
            
            HStack {
                Text("\(imageCount) Pages Scanned")
                    .foregroundColor(.gold)
                
                Spacer()
                
                Button("Snap") {
                    // Simulate capture
                    let mockData = Data() 
                    manager.addImage(mockData)
                }
                .padding()
                .background(Circle().fill(Color.white))
                
                if imageCount > 0 {
                    Button("Done") {
                        Task { await manager.generateRecommendation() }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gold))
                    .foregroundColor(.black)
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
                .tint(.gold)
            Text(stage)
                .font(.headline)
                .foregroundColor(.gold)
                .padding(.top)
        }
    }
}

struct ChefCardView: View {
    let recommendation: MenuRecommendation
    @EnvironmentObject var manager: AmbrosiaManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Chef's Choice")
                .font(.caption)
                .textCase(.uppercase)
                .foregroundColor(.gray)
            
            Text(recommendation.translation.localizedName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if let url = recommendation.imageURL {
                AsyncImage(url: url) { image in
                    image.resizable()
                         .aspectRatio(contentMode: .fill)
                         .frame(height: 200)
                         .cornerRadius(12)
                         .clipped()
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 200)
                }
                .padding(.horizontal)
            }
            
            Text(recommendation.recommendedItem.originalName)
                .font(.title3)
                .italic()
                .foregroundColor(.gold)
            
            Divider().background(Color.gray)
            
            Text(recommendation.translation.culturalContext)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .padding()
            
            if !recommendation.translation.warnings.isEmpty {
                HStack {
                    ForEach(recommendation.translation.warnings, id: \.self) { warn in
                        Text(warn)
                            .font(.caption)
                            .padding(6)
                            .background(Color.red.opacity(0.3))
                            .cornerRadius(4)
                            .foregroundColor(.pink)
                    }
                }
            }
            
            Spacer()
            
            Button("Reset") {
                manager.startSession() // Reset for demo
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.8)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gold, lineWidth: 1))
        .padding()
    }
}

struct ErrorView: View {
    let message: String
    @EnvironmentObject var manager: AmbrosiaManager
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Oops!")
                .font(.title)
                .foregroundColor(.white)
            Text(message)
                .foregroundColor(.gray)
                .padding()
            Button("Try Again") {
                manager.startSession()
            }
        }
    }
}

// Helper Extension
extension Color {
    static let gold = Color(red: 0.83, green: 0.68, blue: 0.21)
}

extension AppState: Equatable {
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.scanning, .scanning): return true
        case (.decoding, .decoding): return true
        case (.reasoning, .reasoning): return true
        case (.verifying, .verifying): return true
        case (.result, .result): return true
        case (.error, .error): return true
        default: return false
        }
    }
}
