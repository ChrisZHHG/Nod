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
    @State private var timer: Timer?
    @State private var time: Float = 0
    
    var body: some View {
        GeometryReader { proxy in
            Group {
                if #available(iOS 18.0, *) {
                    // True MeshGradient for 2026 aesthetics
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
                    // Fallback for sub-iOS 18
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

// MARK: - Awwwards Abstract Graphics

/// Abstract geometric wireframe rotating over time for an avant-garde aesthetic.
struct KineticWireframe: View {
    @State private var rotation: Double = 0
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let slowTime = time * 0.2
                
                Canvas { context, canvasSize in
                    context.translateBy(x: canvasSize.width / 2, y: canvasSize.height / 2)
                    
                    for i in 0..<12 {
                        let offset = Double(i) * (.pi / 6)
                        let currentRotation = slowTime + offset
                        
                        // Create a tilted ellipse that rotates
                        var path = Path()
                        let width = canvasSize.width * 0.8
                        let height = canvasSize.height * 0.2 + (sin(slowTime * 0.5) * canvasSize.height * 0.1)
                        
                        path.addEllipse(in: CGRect(x: -width/2, y: -height/2, width: width, height: height))
                        
                        let transform = CGAffineTransform(rotationAngle: currentRotation)
                        let transformedPath = path.applying(transform)
                        
                        context.stroke(
                            transformedPath,
                            with: .color(AmbrosiaTheme.Awwwards.inkBlack.opacity(0.15)),
                            lineWidth: 0.5
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Subtle paper noise overlay to give the app depth and texture.
struct NoiseOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                for _ in 0..<1500 {
                    let rx = CGFloat.random(in: 0...size.width)
                    let ry = CGFloat.random(in: 0...size.height)
                    let dotSize = CGFloat.random(in: 0.5...1.5)
                    let color = Bool.random() ? Color.black.opacity(0.04) : Color.white.opacity(0.02)
                    
                    var path = Path()
                    path.addEllipse(in: CGRect(x: rx, y: ry, width: dotSize, height: dotSize))
                    context.fill(path, with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

