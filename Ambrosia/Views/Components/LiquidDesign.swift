import SwiftUI

// MARK: - Modern Background System

/// Primary background — clean animated mesh gradient (iOS 18+), linear gradient fallback.
struct ImmersiveBackground: View {
    var body: some View {
        ModernLightBackground()
    }
}

// MARK: - Modern Light Background

struct ModernLightBackground: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            Group {
                if #available(iOS 18.0, *) {
                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: [
                            [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                            [0.0, 0.5], [animate ? 0.3 : 0.6, animate ? 0.7 : 0.4], [1.0, 0.5],
                            [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                        ],
                        colors: [
                            Color(hex: "F8FAFC"), Color(hex: "EFF6FF"), Color(hex: "F8FAFC"),
                            Color(hex: "F1F5F9"), Color(hex: "E0E7FF"), Color(hex: "F3E8FF"),
                            Color(hex: "FFFFFF"), Color(hex: "F8FAFC"), Color(hex: "FFFFFF")
                        ]
                    )
                    .onAppear {
                        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                            animate.toggle()
                        }
                    }
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: "F8FAFC"), Color(hex: "EFF6FF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Circle()
                            .fill(Color(hex: "E0E7FF").opacity(0.5))
                            .frame(width: max(proxy.size.width, proxy.size.height) * 1.5)
                            .blur(radius: 100)
                            .offset(x: animate ? -50 : 50, y: animate ? -50 : 100)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                            animate.toggle()
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
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
