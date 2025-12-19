import SwiftUI

// MARK: - Liquid Glass Design System (iOS 26)

struct LiquidBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Deep Liquid Base (Deep Slate/Black)
            Color(hex: "050505").ignoresSafeArea()
            
            // Fluid Orbs - Subtle and Deep
            // Orb 1: Deep Indigo
            Circle()
                .fill(Color(hex: "1a1a2e").opacity(0.6))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: animate ? -120 : 120, y: animate ? -80 : 80)
            
            // Orb 2: Deep Purple/Gold hint
            Circle()
                .fill(Color(hex: "2d1b36").opacity(0.5))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: animate ? 120 : -120, y: animate ? 100 : -100)
            
            // Orb 3: Subtle Warmth
            Circle()
                .fill(Color(hex: "1c1c1c").opacity(0.8))
                .frame(width: 400, height: 400)
                .blur(radius: 90)
                .offset(x: animate ? -50 : 50, y: animate ? 150 : -150)
            
            // The "Glass" Surface - Ultra Thin Material for the frost effect
            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

// Helper for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}
