import SwiftUI

// MARK: - Processing View — Cinematic "Simmer" Overlay

/// Full-screen overlay shown while agents are processing.
/// Matches the liquid glass dark aesthetic of the landing screen.
struct ProcessingView: View {
    let appState: AppState

    // Breathing animation state
    @State private var textOpacity: Double = 0
    @State private var dotCount: Int = 0
    @State private var iconScale: Double = 0.85

    // State-driven display content
    private var content: (icon: String, headline: String, subline: String) {
        switch appState {
        case .decoding:
            return ("doc.text.viewfinder", "Reading the menu", "Scanning every dish, price, and note")
        case .reasoning(let stage):
            let sub = stage.isEmpty ? "Crafting the perfect choice for you" : stage
            return ("sparkles", "Simmering", sub)
        case .verifying:
            return ("checkmark.shield", "Auditing safety", "Double-checking allergens and restrictions")
        default:
            return ("wand.and.stars", "Working on it", "Just a moment")
        }
    }

    var body: some View {
        ZStack {
            // ── Full-bleed background ──────────────────────────────────────
            Color.black.opacity(0.82).ignoresSafeArea()
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

                // Headline — large, liquid glass
                Text(content.headline + dots)
                    .font(.system(size: 46, weight: .light, design: .rounded))
                    .foregroundStyle(.ultraThinMaterial)
                    .shadow(color: .white.opacity(0.28), radius: 4, x: 0, y: 1)
                    .opacity(textOpacity)
                    .animation(.easeInOut(duration: 0.6), value: content.headline)

                // Subline — smaller, dimmer
                Text(content.subline)
                    .font(.system(size: 16, weight: .light, design: .rounded))
                    .foregroundStyle(.ultraThinMaterial)
                    .opacity(textOpacity * 0.65)
                    .padding(.top, 10)
                    .animation(.easeInOut(duration: 0.6), value: content.subline)

                Spacer()
            }
            .padding(.leading, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .ignoresSafeArea()
        .onAppear { startAnimations() }
        .transition(.opacity.combined(with: .scale(scale: 1.04)))
    }

    // ── Trailing animated dots ─────────────────────────────────────────────
    private var dots: String {
        String(repeating: ".", count: dotCount)
    }

    private func startAnimations() {
        // Fade in text
        withAnimation(.easeOut(duration: 0.7)) { textOpacity = 1.0 }

        // Icon breathing
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            iconScale = 1.0
        }

        // Dot ticker: ., .., ..., reset
        Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { timer in
            dotCount = (dotCount + 1) % 4
            // Stop if we've been cancelled (view left screen)
        }
    }
}
