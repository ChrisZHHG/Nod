import SwiftUI

struct ChefCardView: View {
    let recommendation: MenuRecommendation
    var isEmbedded: Bool = false
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
                        NodTheme.Cinematic.richBrown
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
            NodTheme.Cinematic.heroOverlay
                .ignoresSafeArea()
            
            // ── Instagram-Style Ingredient Tags (float over image) ───────────
            if let ingredients = recommendation.recommendedItem.ingredients,
               !ingredients.isEmpty {
                VStack {
                    // Position tags at ~40% down the screen (mid-image area)
                    Spacer().frame(height: UIScreen.main.bounds.height * 0.30)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Show max 5 most distinctive ingredients
                            ForEach(Array(ingredients.prefix(5)), id: \.self) { ingredient in
                                HStack(spacing: 4) {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.9))
                                    Text(ingredient.uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .tracking(1)
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(.ultraThinMaterial)
                                .environment(\.colorScheme, .dark)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .allowsHitTesting(false) // Tags don't intercept scroll/tap gestures
            }
            
            // ── Main Content Scroll ───────────────────────────────────────────
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // Push content down to expose the massive image
                    Spacer(minLength: UIScreen.main.bounds.height * 0.40)
                    
                    // ── Info Panel (dark glass) ─────────────────────────────
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // ── MOOD LABEL (Hero Title) ─────────────────────────
                        // e.g. "Grand Feast", "Light & Fresh", "Hidden Gem"
                        Text(recommendation.optionType.uppercased())
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .tracking(3)
                            .foregroundColor(NodTheme.Cinematic.amber)
                        
                        // ── DISH NAME + PRICE ───────────────────────────────
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(recommendation.recommendedItem.originalName)
                                .font(NodTheme.Cinematic.displayHero)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.6)
                            
                            Spacer()
                            
                            if let price = recommendation.recommendedItem.price {
                                Text(String(format: "$%.2f", price))
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(NodTheme.Cinematic.amber)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(NodTheme.Cinematic.amber.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        // ── TRANSLATED NAME (only for foreign menus) ────────
                        let localizedName = recommendation.translation.localizedName
                        let originalName = recommendation.recommendedItem.originalName
                        if !localizedName.isEmpty && localizedName.lowercased() != originalName.lowercased() {
                            Text("Also known as: \(localizedName)")
                                .font(.system(size: 13, weight: .light, design: .default).italic())
                                .foregroundColor(NodTheme.Cinematic.smokeGray)
                        }
                        
                        // Separator
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(NodTheme.Cinematic.glassBorder)
                        
                        // ── CULTURAL CONTEXT ────────────────────────────────
                        Text(recommendation.translation.culturalContext)
                            .font(NodTheme.Cinematic.body)
                            .foregroundColor(NodTheme.Cinematic.smokeGray)
                            .lineSpacing(7)

                        
                        // Warnings
                        if !recommendation.translation.warnings.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(recommendation.translation.warnings, id: \.self) { warn in
                                        Text(warn)
                                            .font(NodTheme.Cinematic.caption)
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
                        if !isEmbedded {
                            Button(action: onReset) {
                                HStack {
                                    Spacer()
                                    Text("Scan Another Menu")
                                        .font(NodTheme.Cinematic.cta)
                                        .foregroundColor(NodTheme.Cinematic.deepBlack)
                                    Spacer()
                                }
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(NodTheme.Cinematic.amber)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                        }
                    }
                    .padding(28)
                    .background(
                        ZStack {
                            Rectangle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
                            NodTheme.Cinematic.glassDark
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(NodTheme.Cinematic.glassBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            
            // ── Floating Back ─────────────────────────────────────────────────
            if !isEmbedded {
                FloatingBackButton { onReset() }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}
