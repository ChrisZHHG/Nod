import SwiftUI

struct ComboResultView: View {
    let combo: ComboRecommendation
    var isEmbedded: Bool = false
    let onRefine: (String) -> Void
    
    @State private var refinementText: String = ""
    @State private var isRefining: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            AmbrosiaTheme.Cinematic.deepBlack.ignoresSafeArea()
            
            // ── Full-Bleed Hero Image Background ────────────────────────────────
            GeometryReader { geo in
                AsyncImage(url: combo.imageURL) { phase in
                    if let img = phase.image {
                        img.resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
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
            
            // ── Cinematic Gradient ──────────────────────────────────────────────
            AmbrosiaTheme.Cinematic.heroOverlay
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // Push content down to expose the massive hero image
                    Spacer(minLength: UIScreen.main.bounds.height * 0.35)
                    
                    // ── Combo Name & Quick Stats ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FEAST FOR \(combo.dishes.count + combo.drinks.count)")
                                .font(AmbrosiaTheme.Cinematic.sectionTitle)
                                .tracking(2.5)
                                .foregroundColor(AmbrosiaTheme.Cinematic.amber)
                            
                            Text(combo.optionType)
                                .font(AmbrosiaTheme.Cinematic.displayHero)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.65)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
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
                    if !isEmbedded {
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
                                GlassButton(title: "Refine This Selection", icon: "slider.horizontal.3", variant: .primary) {
                                    withAnimation(.spring()) { isRefining = true }
                                }
                            }
                        }
                        .padding(24)
                    }
                    
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(dish.originalName)
                        .font(AmbrosiaTheme.Cinematic.itemTitle)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        
                    if let desc = dish.description, !desc.isEmpty {
                        Text(desc)
                            .font(AmbrosiaTheme.Cinematic.caption)
                            .foregroundColor(AmbrosiaTheme.Cinematic.smokeGray)
                            .lineLimit(2)
                    }
                    
                    // ── Instagram-Style Ingredient Tags ─────────────────────
                    if let ingredients = dish.ingredients, !ingredients.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(ingredients, id: \.self) { ingredient in
                                    HStack(spacing: 3) {
                                        Image(systemName: "tag.fill")
                                            .font(.system(size: 7))
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(ingredient.uppercased())
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .tracking(1)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                    )
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                Spacer()
                if let price = dish.price {
                    Text(String(format: "$%.2f", price))
                        .font(AmbrosiaTheme.Cinematic.body)
                        .foregroundColor(AmbrosiaTheme.Cinematic.smokeGray)
                        .padding(.top, 4)
                }
            }
            
            // Dish Image
            if let imageURL = dish.imageURL {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.lg, style: .continuous))
                    } else if phase.error != nil {
                        // Error State, hidden
                        EmptyView()
                    } else {
                        // Loading State
                        RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.lg, style: .continuous)
                            .fill(AmbrosiaTheme.Cinematic.glassDark)
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .overlay(ProgressView().tint(AmbrosiaTheme.Cinematic.amber))
                    }
                }
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
