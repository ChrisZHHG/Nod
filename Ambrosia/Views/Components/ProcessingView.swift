import SwiftUI

struct ProcessingView: View {
    let status: String
    let progress: Double
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .frame(width: 200)
            
            Text(status)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
                .transition(.opacity)
                .id(status) // Force transition when text changes
        }
        .padding(40)
        .glassCard()
    }
}
