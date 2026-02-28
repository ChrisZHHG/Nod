import SwiftUI

// MARK: - Processing View — Cinematic "Simmer" Overlay

/// Full-screen overlay shown while agents are processing.
/// Matches the liquid glass dark aesthetic of the landing screen.
struct ProcessingView: View {
    let store: AppStore

    @State private var textOpacity: Double = 0
    @State private var dotCount: Int = 0
    @State private var iconScale: Double = 0.85
    @State private var typewriterText: String = ""

    private var content: (icon: String, headline: String, subline: String) {
        switch store.appState {
        case .decoding:
            return ("doc.text.viewfinder", "Reading the menu", "Scanning every dish, price, and note...")
        case .reasoning(let stage):
            let sub = stage.isEmpty ? "Crafting the perfect choice for you..." : stage
            return ("sparkles", "Simmering", sub)
        case .verifying:
            return ("checkmark.shield", "Auditing safety", "Double-checking allergens and restrictions...")
        default:
            return ("wand.and.stars", "Working on it", "Just a moment...")
        }
    }

    var body: some View {
        ZStack {
            // ── Full-bleed Cinematic Background ──────────────────────────────────────
            if let firstImg = store.capturedImages.first, let uiImage = UIImage(data: firstImg) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 60)
                    .overlay(Color.black.opacity(0.5))
            } else {
                Color.black.opacity(0.82).ignoresSafeArea()
            }
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .ignoresSafeArea()

            // ── Content stack (top-left aligned, mirrors landing screen) ──
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Animated SF icon
                Image(systemName: content.icon)
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundStyle(.ultraThinMaterial)
                    .shadow(color: .white.opacity(0.25), radius: 6, x: 0, y: 2)
                    .scaleEffect(iconScale)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: iconScale)
                    .padding(.bottom, 28)
                    .frame(height: 70, alignment: .bottomLeading) // Fixed height prevents jumping

                // Headline — large, liquid glass
                Text(content.headline + dots)
                    .font(.system(size: 46, weight: .light, design: .rounded))
                    .foregroundStyle(.ultraThinMaterial)
                    .shadow(color: .white.opacity(0.28), radius: 4, x: 0, y: 1)
                    .opacity(textOpacity)
                    .animation(.easeInOut(duration: 0.6), value: content.headline)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading) // Lock height

                // Subline Typewriter
                Text(typewriterText)
                    .font(.system(size: 18, weight: .light, design: .rounded))
                    .foregroundStyle(.ultraThinMaterial)
                    .opacity(textOpacity * 0.8)
                    .padding(.top, 10)
                    .frame(minHeight: 60, alignment: .topLeading)

                Spacer()
            }
            .padding(.leading, 32)
            .padding(.trailing, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .ignoresSafeArea()
        .onAppear { startAnimations() }
        .onChange(of: content.subline) { _, newSubline in
            startTypewriter(for: newSubline)
        }
        .transition(.opacity.combined(with: .scale(scale: 1.04)))
    }

    private var dots: String {
        String(repeating: ".", count: dotCount)
    }

    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.7)) { textOpacity = 1.0 }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            iconScale = 1.0
        }
        Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { _ in
            dotCount = (dotCount + 1) % 4
        }
        startTypewriter(for: content.subline)
    }
    
    // Smooth fast typewriter effect
    private func startTypewriter(for text: String) {
        typewriterText = ""
        let chars = Array(text)
        var currentIndex = 0
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if currentIndex < chars.count {
                typewriterText.append(chars[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}
