import SwiftUI

struct ComboResultView: View {
    let combo: ComboRecommendation
    let onRefine: (String) -> Void
    
    @State private var refinementText: String = ""
    @State private var isRefining: Bool = false
    
    var body: some View {
        ZStack {
            AmbrosiaTheme.Cinematic.deepBlack.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // ── Hero Image ───────────────────────────────────────────────
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: combo.imageURL) { phase in
                            if let img = phase.image {
                                img.resizable()
                                    .scaledToFill()
                                    .frame(height: 320)
                                    .clipped()
                            } else {
                                AmbrosiaTheme.Cinematic.richBrown
                                    .frame(height: 320)
                                    .overlay(
                                        Image(systemName: "fork.knife")
                                            .font(.system(size: 50, weight: .ultraLight))
                                            .foregroundColor(.white.opacity(0.15))
                                    )
                            }
                        }
                        
                        // Gradient vignette
                        AmbrosiaTheme.Cinematic.cardOverlay
                            .frame(height: 320)
                        
                        // Combo name overlay
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FEAST FOR \(combo.dishes.count + combo.drinks.count)")
                                .font(AmbrosiaTheme.Cinematic.sectionTitle)
                                .tracking(2.5)
                                .foregroundColor(AmbrosiaTheme.Cinematic.amber)
                            
                            Text(combo.name)
                                .font(AmbrosiaTheme.Cinematic.displayHero)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.65)
                        }
                        .padding(24)
                    }
                    
                    // ── Quick Stats strip ─────────────────────────────────────────
                    HStack(spacing: 0) {
                        statPill(icon: "dollarsign.circle", value: String(format: "$%.0f", combo.totalPrice), label: "Total")
                        Divider().frame(height: 30).background(AmbrosiaTheme.Cinematic.glassBorder)
                        statPill(icon: "fork.knife", value: "\(combo.dishes.count)", label: "Dishes")
                        Divider().frame(height: 30).background(AmbrosiaTheme.Cinematic.glassBorder)
                        statPill(icon: "wineglass", value: "\(combo.drinks.count)", label: "Drinks")
                    }
                    .padding(.vertical, 18)
                    .background(AmbrosiaTheme.Cinematic.glassDark)
                    .overlay(
                        Rectangle()
                            .stroke(AmbrosiaTheme.Cinematic.glassBorder, lineWidth: 1)
                    )
                    
                    // ── Reasoning ────────────────────────────────────────────────
                    Text(combo.reasoning)
                        .font(AmbrosiaTheme.Cinematic.body)
                        .foregroundColor(AmbrosiaTheme.Cinematic.smokeGray)
                        .lineSpacing(7)
                        .padding(24)
                    
                    // ── Dishes ────────────────────────────────────────────────────
                    sectionHeader("THE MENU")
                    
                    ForEach(combo.dishes, id: \.self) { dish in
                        DishRow(dish: dish)
                    }
                    
                    // ── Drinks ─────────────────────────────────────────────────────
                    sectionHeader("SOMMELIER'S CHOICE")
                    
                    ForEach(combo.drinks) { drink in
                        DrinkRow(drink: drink)
                    }
                    
                    // ── Refinement ─────────────────────────────────────────────────
                    VStack(spacing: 16) {
                        if isRefining {
                            HStack(spacing: 0) {
                                TextField("e.g. More seafood, something fried...", text: $refinementText)
                                    .font(AmbrosiaTheme.Cinematic.body)
                                    .foregroundColor(.white)
                                    .padding(14)
                                    .background(AmbrosiaTheme.Cinematic.glassDark)
                                
                                Button(action: {
                                    onRefine(refinementText)
                                    refinementText = ""
                                    isRefining = false
                                }) {
                                    Text("GO")
                                        .font(AmbrosiaTheme.Cinematic.cta)
                                        .foregroundColor(AmbrosiaTheme.Cinematic.deepBlack)
                                        .padding(.horizontal, 24)
                                        .frame(maxHeight: .infinity)
                                        .background(AmbrosiaTheme.Cinematic.amber)
                                }
                            }
                            .frame(height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AmbrosiaTheme.Cinematic.glassBorder, lineWidth: 1)
                            )
                        } else {
                            Button(action: { withAnimation(.spring()) { isRefining = true } }) {
                                HStack {
                                    Spacer()
                                    Text("Refine This Selection")
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
                        }
                    }
                    .padding(24)
                    
                    Spacer(minLength: 60)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(AmbrosiaTheme.Cinematic.sectionTitle)
                .tracking(2.5)
                .foregroundColor(AmbrosiaTheme.Cinematic.amber)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }
    
    private func statPill(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AmbrosiaTheme.Cinematic.amber)
                Text(value)
                    .font(AmbrosiaTheme.Cinematic.itemTitle)
                    .foregroundColor(.white)
            }
            Text(label)
                .font(AmbrosiaTheme.Cinematic.caption)
                .foregroundColor(AmbrosiaTheme.Cinematic.smokeGray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InfoChip: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(AmbrosiaTheme.Cinematic.amber)
            Text(text)
                .font(AmbrosiaTheme.Cinematic.sectionTitle)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(AmbrosiaTheme.Cinematic.glassDark)
        .clipShape(Capsule())
        .foregroundStyle(.white)
    }
}

struct DishRow: View {
    let dish: RecommendedItem
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(dish.originalName)
                    .font(AmbrosiaTheme.Cinematic.itemTitle)
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            Spacer()
            if let price = dish.price {
                Text(String(format: "$%.2f", price))
                    .font(AmbrosiaTheme.Cinematic.body)
                    .foregroundColor(AmbrosiaTheme.Cinematic.smokeGray)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(
            Rectangle()
                .fill(AmbrosiaTheme.Cinematic.glassDark.opacity(0.4))
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AmbrosiaTheme.Cinematic.glassBorder),
            alignment: .bottom
        )
    }
}

struct DrinkRow: View {
    let drink: DrinkRecommendation
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: drink.type == "Alcoholic" ? "wineglass.fill" : "cup.and.saucer.fill")
                .font(.system(size: 16))
                .foregroundColor(AmbrosiaTheme.Cinematic.amber)
                .padding(.top, 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(drink.name)
                    .font(AmbrosiaTheme.Cinematic.itemTitle)
                    .foregroundColor(.white)
                Text(drink.pairingReason)
                    .font(AmbrosiaTheme.Cinematic.body)
                    .foregroundColor(AmbrosiaTheme.Cinematic.smokeGray)
                    .lineLimit(3)
                    .lineSpacing(4)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(
            Rectangle()
                .fill(AmbrosiaTheme.Cinematic.glassDark.opacity(0.4))
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AmbrosiaTheme.Cinematic.glassBorder),
            alignment: .bottom
        )
    }
}
