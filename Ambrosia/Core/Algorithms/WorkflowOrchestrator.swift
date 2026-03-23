import Foundation

enum EngineOutput: Sendable {
    case individual(SoloRecommendationSet, MenuData)
    case group(GroupRecommendationSet, MenuData)
}

/// Orchestrates the entire multi-agent recommendation pipeline.
/// Completely decoupled from UI state and typed securely against NodError.
actor WorkflowOrchestrator {
    private let dependencies: DependencyContainer
    
    init(dependencies: DependencyContainer = .shared) {
        self.dependencies = dependencies
    }
    
    func executePipeline(
        mode: AppMode,
        images: [Data],
        individualProfile: IndividualProfile,
        groupProfile: GroupProfile,
        cachedMenu: MenuData?,
        pendingDecodingTask: Task<MenuData, Error>?,
        onProgress: @Sendable @escaping (Double, String) -> Void
    ) async -> Result<EngineOutput, NodError> {
        
        guard !images.isEmpty else {
            return .failure(.noImagesCaptured)
        }
        
        do {
            // STEP 1: Decode
            onProgress(0.1, "Reading Menu...")
            let menuData: MenuData
            
            if let cached = cachedMenu {
                menuData = cached
            } else if let pendingTask = pendingDecodingTask {
                menuData = try await pendingTask.value
            } else {
                do {
                    menuData = try await dependencies.decoder.decode(images: images)
                } catch {
                    return .failure(.decodingFailed(reason: error.localizedDescription))
                }
            }
            
            // STEP 2: Research Requirements
            onProgress(0.3, "Gathering Restaurant Insights...")
            let researchData = try? await dependencies.research.researchRestaurant(
                name: menuData.metadata.restaurantName ?? "Restaurant",
                location: nil
            )
            
            // STEP 3: Fork based on Mode
            if mode == .individual {
                onProgress(0.5, "Personalizing for You...")
                let result = try await handleIndividualFlow(
                    menuData: menuData,
                    profile: individualProfile,
                    research: researchData,
                    onProgress: onProgress
                )
                return .success(.individual(result, menuData))
            } else {
                onProgress(0.5, "Assembling Group Combos...")
                let result = try await handleGroupFlow(
                    menuData: menuData,
                    profile: groupProfile,
                    research: researchData,
                    onProgress: onProgress
                )
                return .success(.group(result, menuData))
            }
            
        } catch let ambrosiaError as NodError {
            return .failure(ambrosiaError)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    private func handleIndividualFlow(
        menuData: MenuData,
        profile: IndividualProfile,
        research: RestaurantResearchData?,
        onProgress: @Sendable @escaping (Double, String) -> Void
    ) async throws -> SoloRecommendationSet {
        var draftSet = try await dependencies.chef.recommend(from: menuData, profile: profile, research: research)
        
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
        
        // Rebuild immutable array, preserving all fields including ingredients
        let updatedOptions = draftSet.options.enumerated().map { (index, oldOption) in
            let updatedItem = RecommendedItem(
                originalName: oldOption.recommendedItem.originalName,
                description: oldOption.recommendedItem.description,
                price: oldOption.recommendedItem.price,
                ingredients: oldOption.recommendedItem.ingredients, // ← was previously dropped
                imageURL: oldOption.recommendedItem.imageURL
            )
            return MenuRecommendation(
                id: oldOption.id,
                optionType: oldOption.optionType,
                recommendedItem: updatedItem,
                translation: oldOption.translation,
                reasoning: oldOption.reasoning,
                pairings: oldOption.pairings,
                imageURL: visualUrls[index] ?? nil
            )
        }
        draftSet = SoloRecommendationSet(options: updatedOptions)
        
        // Safety Audit
        onProgress(0.9, "Auditing Recommendations...")
        let verifiedResult = try await dependencies.safety.audit(draft: draftSet, context: menuData, profile: profile)
        return verifiedResult
    }
    
    private func handleGroupFlow(
        menuData: MenuData,
        profile: GroupProfile,
        research: RestaurantResearchData?,
        onProgress: @Sendable @escaping (Double, String) -> Void
    ) async throws -> GroupRecommendationSet {
        var draftSet = try await dependencies.chef.recommendCombo(from: menuData, group: profile, research: research)
        
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
        
        let updatedCombos = draftSet.combos.enumerated().map { (comboIndex, oldCombo) in
            let updatedDishes = oldCombo.dishes.enumerated().map { (dishIndex, oldDish) in
                var newDish = oldDish
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
        onProgress(0.9, "Auditing Combos...")
        let verifiedCombo = try await dependencies.safety.auditCombo(draft: draftSet, context: menuData, group: profile)
        return verifiedCombo
    }
}
