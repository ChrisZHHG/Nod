import SwiftUI

struct ComboResultView: View {
    let combo: ComboRecommendation
    let onRefine: (String) -> Void
    
    @State private var refinementText: String = ""
    @State private var isRefining: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Visualize Header
                if let url = combo.imageURL {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Color.black.opacity(0.3)
                        }
                    }
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .overlay(
                        LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .bottom, endPoint: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 32))
                    )
                    .overlay(
                        Text(combo.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding()
                        , alignment: .bottomLeading
                    )
                }
                
                // Summary Cards
                HStack(spacing: 12) {
                    InfoChip(icon: "dollarsign.circle", text: String(format: "$%.0f", combo.totalPrice))
                    InfoChip(icon: "fork.knife", text: "\(combo.dishes.count) Dishes")
                    InfoChip(icon: "wineglass", text: "\(combo.drinks.count) Drinks")
                }
                
                // Reasoning
                Text(combo.reasoning)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                
                // Dishes List
                VStack(alignment: .leading, spacing: 16) {
                    Text("The Menu")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.leading)
                    
                    ForEach(combo.dishes) { dish in
                        DishRow(dish: dish)
                    }
                }
                .padding(.horizontal)
                
                // Drinks List
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sommelier Selection")
                        .font(.headline)
                        .foregroundStyle(.purple.opacity(0.8))
                        .padding(.leading)
                    
                    ForEach(combo.drinks) { drink in
                        DrinkRow(drink: drink)
                    }
                }
                .padding(.horizontal)
                
                // Refinement Loop
                VStack(spacing: 12) {
                    Text("Not what you wanted?")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    if isRefining {
                        HStack {
                            TextField("e.g. Seafood, Something Fried...", text: $refinementText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Go") {
                                onRefine(refinementText)
                                refinementText = ""
                                isRefining = false
                            }
                            .interactiveDismissDisabled()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        GlassButton(title: "I want something else...", icon: "arrow.triangle.2.circlepath") {
                            withAnimation { isRefining = true }
                        }
                    }
                }
                .padding(24)
                
                Spacer(minLength: 50)
            }
        }
        .background(LiquidBackground())
    }
}

struct InfoChip: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .foregroundStyle(.white)
    }
}

struct DishRow: View {
    let dish: MenuItem
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(dish.originalName)
                    .font(.body)
                    .foregroundStyle(.white)
                if let price = dish.price {
                    Text(String(format: "$%.2f", price))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DrinkRow: View {
    let drink: DrinkRecommendation
    var body: some View {
        HStack {
            Image(systemName: drink.type == "Alcoholic" ? "wineglass.fill" : "mug.fill")
                .foregroundStyle(drink.type == "Alcoholic" ? .pink : .mint)
            
            VStack(alignment: .leading) {
                Text(drink.name)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                Text(drink.pairingReason)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
