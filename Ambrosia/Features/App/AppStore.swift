import Foundation
import SwiftUI

// MARK: - App Domain (State, Action, Effect)

/// Application-wide state following TCA patterns
@Observable
@MainActor
final class AppStore {
    // MARK: - State
    
    var mode: AppMode = .individual
    var appState: AppState = .idle
    // Enforce private(set) to stop external UI mutations
    private(set) var individualProfile: IndividualProfile = .init()
    private(set) var groupProfile: GroupProfile = .init()
    var capturedImages: [Data] = []
    var cachedParsedMenu: MenuData? = nil
    private var decodingTask: Task<MenuData, Error>?
    var timelineLog: [String] = []
    
    // Navigation (using enum path for type-safe navigation)
    var navigationPath: [AppDestination] = []
    
    // Dependencies
    private let dependencies: DependencyContainer
    
    init(dependencies: DependencyContainer = .shared) {
        self.dependencies = dependencies
    }
    
    // MARK: - Actions (via methods that mirror TCA Action enum)
    
    func setMode(_ mode: AppMode) {
        self.mode = mode
        self.appState = .idle
        self.capturedImages = []
        log("🔄 Switched to \(mode) mode.")
    }
    
    // Explicit Intent to modify profiles centrally
    func updateIndividualProfile(_ update: (inout IndividualProfile) -> Void) {
        update(&individualProfile)
        log("👤 Individual Profile Updated: Vetoes[\(individualProfile.vetoes.count)] Cravings[\(individualProfile.cravings.count)]")
    }
    
    func updateGroupProfile(_ update: (inout GroupProfile) -> Void) {
        update(&groupProfile)
        log("👥 Group Profile Updated: Size[\(groupProfile.headcount)] Vetoes[\(groupProfile.vetoes.count)] Cravings[\(groupProfile.cravings.count)]")
    }
    
    func startSession() {
        self.appState = .scanning
        navigationPath.append(.scanner)
        log("👨‍✈️ Session Started (\(mode)).")
    }
    
    func resetSession() {
        self.appState = .idle
        self.navigationPath = []
        self.capturedImages = []
        self.cachedParsedMenu = nil
        self.decodingTask?.cancel()
        self.decodingTask = nil
        log("🔄 Session Reset.")
    }
    
    func captureImage(_ imageData: Data) {
        guard appState == .scanning else { return }
        capturedImages.append(imageData)
        self.cachedParsedMenu = nil // Invalidate on new photo
        self.decodingTask?.cancel()
        log("📸 Image Captured. Total: \(capturedImages.count)")
        
        // CONCURRENCY TRICK: Start the heavy OCR immediately, 
        // hiding the latency behind the upcoming Progressive UI Wizard.
        self.decodingTask = Task {
            log("👀 Decoder Agent: Background Scanning Menu...")
            let data = try await dependencies.decoder.decode(images: capturedImages)
            self.cachedParsedMenu = data
            log("👀 Decoder Agent: Background Scan Complete.")
            return data
        }
    }
    
    // MARK: - Effects (Async Operations)
    
    func generateRecommendation() async {
        guard !capturedImages.isEmpty else {
            self.appState = .error("No images captured")
            return
        }
        
        do {
            // Step 1: Decode first (we need the name for Research)
            self.appState = .decoding(progress: 0.5)
            
            let menuData: MenuData
            if let cached = cachedParsedMenu {
                log("👀 Using cached menu parsing. Skipping OCR...")
                menuData = cached
            } else if let pendingTask = decodingTask {
                log("👀 Waiting for background Decoder Agent to finish...")
                menuData = try await pendingTask.value
                self.cachedParsedMenu = menuData
            } else {
                log("👀 Decoder Agent: Scanning Menu (Synchronous Fallback)...")
                menuData = try await dependencies.decoder.decode(images: capturedImages)
                self.cachedParsedMenu = menuData
            }
            
            // Step 1.5: Research (Now we have the restaurant name)
            log("🔍 Gathering Restaurant Insights for '\(menuData.metadata.restaurantName ?? "Unknown")'...")
            let researchData = try? await dependencies.research.researchRestaurant(
                name: menuData.metadata.restaurantName ?? "Restaurant",
                location: nil // Could optionally pass CoreLocation data here later
            )
            
            if let research = researchData {
                log("🔍 Fetched Google Research: \(research.rating ?? 0) stars, Vibe: \(research.generalVibe.prefix(30))...")
            } else {
                log("🔍 Failed or skipped fetching Google Research.")
            }
            
            // Step 2: Fork based on Mode
            if mode == .individual {
                try await handleIndividualFlow(using: menuData, research: researchData)
            } else {
                try await handleGroupFlow(using: menuData, research: researchData)
            }
            
        } catch {
            self.appState = .error(error.localizedDescription)
            log("❌ Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Effects
    
    private func handleIndividualFlow(using menuData: MenuData, research: RestaurantResearchData?) async throws {
        self.appState = .reasoning(stage: "Personalizing for You...")
        log("👨‍🍳 Chef Agent: Crafting 3 recommendations...")
        
        var draftSet = try await dependencies.chef.recommend(from: menuData, profile: individualProfile, research: research)
        
        // Visualizer (Parallel tasking for all 3 options without mutating models in place)
        let visualUrls: [Int: URL?] = await withTaskGroup(of: (Int, URL?).self) { group in
            for (index, option) in draftSet.options.enumerated() {
                let dishName = option.translation.localizedName
                let desc = option.translation.culturalContext
                group.addTask {
                    let url = try? await self.dependencies.visualizer.visualize(dishName: dishName, description: desc)
                    return (index, url)
                }
            }
            
            var results: [Int: URL?] = [:]
            for await (index, url) in group {
                results[index] = url
            }
            return results
        }
        
        // Rebuild immutable array
        let updatedOptions = draftSet.options.enumerated().map { (index, oldOption) in
            MenuRecommendation(
                id: oldOption.id,
                optionType: oldOption.optionType,
                recommendedItem: oldOption.recommendedItem,
                translation: oldOption.translation,
                reasoning: oldOption.reasoning,
                pairings: oldOption.pairings,
                imageURL: visualUrls[index] ?? nil
            )
        }
        draftSet = SoloRecommendationSet(options: updatedOptions)
        
        // Safety Audit
        self.appState = .verifying
        log("🛡️ Safety Agent: Auditing sets...")
        let verifiedResult = try await dependencies.safety.audit(draft: draftSet, context: menuData, profile: individualProfile)
        
        self.appState = .idle
        navigationPath.append(.soloResult(verifiedResult))
        log("🎉 Individual Recommendations Ready.")
    }
    
    private func handleGroupFlow(using menuData: MenuData, research: RestaurantResearchData?) async throws {
        self.appState = .reasoning(stage: "Assembling Group Combos...")
        log("👨‍🍳 Chef Agent: Crafting 3 combos for \(groupProfile.headcount) people...")
        
        var draftSet = try await dependencies.chef.recommendCombo(from: menuData, group: groupProfile, research: research)
        
        // Visualizer: Fetch Hero image + all Dish images concurrently
        // We will store the results in a nested dictionary [ComboIndex: [DishIndex: URL?]]
        // Use -1 for the DishIndex to represent the Combo's Hero image.
        
        let visualResults: [Int: [Int: URL?]] = await withTaskGroup(of: (Int, Int, URL?).self) { taskGroup in
            for (comboIndex, combo) in draftSet.combos.enumerated() {
                // 1. Fetch Hero Image
                let comboName = combo.optionType
                let comboDesc = combo.dishes.map { $0.originalName }.joined(separator: ", ")
                taskGroup.addTask {
                    let url = try? await self.dependencies.visualizer.visualize(dishName: comboName, description: comboDesc)
                    return (comboIndex, -1, url)
                }
                
                // 2. Fetch Dish Images
                for (dishIndex, dish) in combo.dishes.enumerated() {
                    let dishName = dish.originalName
                    let dishDesc = dish.description ?? ""
                    taskGroup.addTask {
                        let url = try? await self.dependencies.visualizer.visualize(dishName: dishName, description: dishDesc)
                        return (comboIndex, dishIndex, url)
                    }
                }
            }
            
            var results: [Int: [Int: URL?]] = [:]
            for await (comboIdx, dishIdx, url) in taskGroup {
                if results[comboIdx] == nil {
                    results[comboIdx] = [:]
                }
                results[comboIdx]?[dishIdx] = url
            }
            return results
        }
        
        // Rebuild immutable array with injected images
        let updatedCombos = draftSet.combos.enumerated().map { (comboIndex, oldCombo) in
            // Rebuild dishes for this combo
            let updatedDishes = oldCombo.dishes.enumerated().map { (dishIndex, oldDish) in
                var newDish = oldDish
                // Grab the specific dish image URL out of the dictionary, if any
                newDish.imageURL = visualResults[comboIndex]?[dishIndex] ?? nil
                return newDish
            }
            
            return ComboRecommendation(
                id: oldCombo.id,
                optionType: oldCombo.optionType,
                dishes: updatedDishes,
                drinks: oldCombo.drinks,
                totalPrice: oldCombo.totalPrice,
                reasoning: oldCombo.reasoning,
                imageURL: visualResults[comboIndex]?[-1] ?? nil
            )
        }
        draftSet = GroupRecommendationSet(combos: updatedCombos)
        
        // Safety Audit
        self.appState = .verifying
        log("🛡️ Safety Agent: Auditing group combos...")
        let verifiedCombo = try await dependencies.safety.auditCombo(draft: draftSet, context: menuData, group: groupProfile)
        
        self.appState = .idle
        navigationPath.append(.groupResult(verifiedCombo))
        log("🎉 Group Feast Options Ready and Verified.")
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        print("[AppStore] \(message)")
        timelineLog.append(message)
    }
}

// MARK: - Navigation Destination

enum AppDestination: Hashable {
    case scanner
    case wizard
    case soloResult(SoloRecommendationSet)
    case groupResult(GroupRecommendationSet)
}
