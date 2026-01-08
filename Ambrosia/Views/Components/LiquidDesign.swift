import SwiftUI

// MARK: - Modern Background System (Clean Minimal / 2025)

/// Primary background - clean light gradient with subtle accent
struct ImmersiveBackground: View {
    var body: some View {
        ModernLightBackground()
    }
}

// MARK: - Modern Light Background

struct ModernLightBackground: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base: Clean light gradient
                LinearGradient(
                    colors: [
                        AmbrosiaTheme.Colors.surfaceElevated,
                        AmbrosiaTheme.Colors.surface,
                        AmbrosiaTheme.Colors.surface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle accent orb (top-right)
                Circle()
                    .fill(AmbrosiaTheme.Colors.accent.opacity(0.08))
                    .frame(width: geo.size.width * 0.6)
                    .blur(radius: 60)
                    .offset(
                        x: geo.size.width * 0.3,
                        y: animate ? -geo.size.height * 0.15 : -geo.size.height * 0.2
                    )
                
                // Secondary orb (bottom-left)
                Circle()
                    .fill(AmbrosiaTheme.Colors.accentSoft.opacity(0.06))
                    .frame(width: geo.size.width * 0.5)
                    .blur(radius: 80)
                    .offset(
                        x: -geo.size.width * 0.25,
                        y: geo.size.height * 0.35
                    )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Legacy Aliases

/// Legacy LiquidBackground - now uses modern light background
struct LiquidBackground: View {
    var body: some View {
        ImmersiveBackground()
    }
}

/// Legacy CoralSunsetMesh - redirects to modern background
@available(iOS 18.0, *)
struct CoralSunsetMesh: View {
    var body: some View {
        ModernLightBackground()
    }
}

/// Legacy fallback
struct LegacyImmersiveBackground: View {
    var body: some View {
        ModernLightBackground()
    }
}

// MARK: - Helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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

