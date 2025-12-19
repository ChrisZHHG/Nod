import SwiftUI

struct GroupSetupView: View {
    @EnvironmentObject var manager: AmbrosiaManager
    @State private var headcount: Double = 4
    @State private var budget: Double = 200
    @State private var selectedAllergies: Set<String> = []
    
    let commonAllergies = ["Peanuts", "Shellfish", "Dairy", "Gluten", "Eggs", "Soy"]
    
    var onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Group Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                // Headcount
                VStack(alignment: .leading) {
                    Text("Headcount: \(Int(headcount))")
                        .foregroundStyle(.gray)
                    Slider(value: $headcount, in: 2...12, step: 1)
                        .tint(.purple)
                }
                
                // Budget
                VStack(alignment: .leading) {
                    Text("Total Budget: $\(Int(budget))")
                        .foregroundStyle(.gray)
                    Slider(value: $budget, in: 50...500, step: 10)
                        .tint(.green)
                }
                
                // Allergies (The Filter)
                VStack(alignment: .leading) {
                    Text("Strict Restrictions")
                        .foregroundStyle(.red)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        ForEach(commonAllergies, id: \.self) { allergy in
                            Button {
                                if selectedAllergies.contains(allergy) {
                                    selectedAllergies.remove(allergy)
                                } else {
                                    selectedAllergies.insert(allergy)
                                }
                            } label: {
                                Text(allergy)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(selectedAllergies.contains(allergy) ? Color.red : Color.white.opacity(0.1))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                // Confirm Button
                GlassButton(title: "Generate Feast", icon: "wand.and.stars") {
                    // Update Manager Profile
                    var profile = GroupProfile()
                    profile.headcount = Int(headcount)
                    profile.budgetTotal = Int(budget)
                    profile.collectiveAllergies = Array(selectedAllergies)
                    manager.groupProfile = profile
                    
                    onConfirm()
                }
                .padding(.top, 20)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .padding(20)
        }
    }
}
