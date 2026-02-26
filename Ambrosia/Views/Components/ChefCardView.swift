import SwiftUI

struct ChefCardView: View {
    let recommendation: MenuRecommendation
    let onReset: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Full-Bleed Food Image ────────────────────────────────────────
            GeometryReader { geo in
                AsyncImage(url: recommendation.imageURL) { phase in
                    if let img = phase.image {
                        img.resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
                        // Dark placeholder when no image ("premium" matte)
                        AmbrosiaTheme.Cinematic.richBrown
                            .frame(width: geo.size.width, height: geo.size.height)
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 60, weight: .ultraLight))
                                    .foregroundColor(.white.opacity(0.15))
                            )
                    }
                }
            }
            .ignoresSafeArea()
            
            // ── Cinematic Gradient ────────────────────────────────────────────
            AmbrosiaTheme.Cinematic.heroOverlay
                .ignoresSafeArea()
            
            // ── Main Content Scroll ───────────────────────────────────────────
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Top spacer so content starts below the fold
                    Spacer(minLength: UIScreen.main.bounds.height * 0.45)
                    
                    // ── Info Panel (dark glass) ─────────────────────────────
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Diet label & category tag row
                        HStack(spacing: 10) {
                            Text("CHEF'S CHOICE")
                                .font(AmbrosiaTheme.Cinematic.sectionTitle)
                                .tracking(2.5)
                                .foregroundColor(AmbrosiaTheme.Cinematic.amber)
                            
                            Spacer()
                            
                            if let price = recommendation.recommendedItem.price {
                                Text(String(format: "$%.2f", price))
                                    .font(AmbrosiaTheme.Cinematic.sectionTitle)
                                    .foregroundColor(AmbrosiaTheme.Cinematic.smokeGray)
                            }
                        }
                        
                        // Dish name (massive)
                        Text(recommendation.translation.localizedName)
                            .font(AmbrosiaTheme.Cinematic.displayHero)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                        
                        // Original name (italic small)
                        Text(recommendation.recommendedItem.originalName)
                            .font(.system(size: 14, weight: .light, design: .default).italic())
                            .foregroundColor(AmbrosiaTheme.Cinematic.smokeGray)
                        
                        // Separator
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(AmbrosiaTheme.Cinematic.glassBorder)
                        
                        // Cultural context body
                        Text(recommendation.translation.culturalContext)
                            .font(AmbrosiaTheme.Cinematic.body)
                            .foregroundColor(AmbrosiaTheme.Cinematic.smokeGray)
                            .lineSpacing(7)
                        
                        // Warnings
                        if !recommendation.translation.warnings.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(recommendation.translation.warnings, id: \.self) { warn in
                                        Text(warn)
                                            .font(AmbrosiaTheme.Cinematic.caption)
                                            .foregroundColor(Color(hex: "FF6B6B"))
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 12)
                                            .background(
                                                Capsule().fill(Color(hex: "FF6B6B").opacity(0.15))
                                            )
                                    }
                                }
                            }
                        }
                        
                        // ── CTA Button ─────────────────────────────────────
                        Button(action: onReset) {
                            HStack {
                                Spacer()
                                Text("Scan Another Menu")
                                    .font(AmbrosiaTheme.Cinematic.cta)
                                    .foregroundColor(AmbrosiaTheme.Cinematic.deepBlack)
                                Spacer()
                            }
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AmbrosiaTheme.Cinematic.amber)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(28)
                    .background(
                        ZStack {
                            Rectangle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
                            AmbrosiaTheme.Cinematic.glassDark
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(AmbrosiaTheme.Cinematic.glassBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            
            // ── Floating Back ─────────────────────────────────────────────────
            FloatingBackButton { onReset() }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}
