import XCTest
@testable import Ambrosia

final class AmbrosiaUnitTests: XCTestCase {
    
    var mockService: MockGeminiService!
    var safetyAgent: SafetyAgent!
    var decoderAgent: DecoderAgent!
    var cultureAgent: CultureAgent!
    
    override func setUp() {
        super.setUp()
        mockService = MockGeminiService()
        safetyAgent = SafetyAgent(service: mockService)
        decoderAgent = DecoderAgent(service: mockService)
        cultureAgent = CultureAgent(service: mockService)
    }
    
    // MARK: - Test 1: Safety Guardrails
    
    func testSafetyAgentBlocksPeanuts() async throws {
        // 1. Setup
        var profile = UserProfile()
        profile.allergies = ["Peanuts"]
        
        let dangerousItem = MenuItem(originalName: "Kung Pao Chicken", description: "Contains peanuts", price: 15, isSpicy: true, isVegetarian: false, containsGluten: false, containsPeanuts: true, containsSeafood: false)
        let badDraft = MenuRecommendation(
            recommendedItem: dangerousItem,
            translation: CulturalTranslation(localizedName: "Kung Pao Chicken", culturalContext: "Tasty chicken with peanuts", warnings: ["Peanuts"]),
            reasoning: "User likes spicy.",
            pairings: []
        )
        let menuData = MenuData(sections: [], currency: "USD", languageDetected: "en", metadata: MenuMetadata(restaurantName: "Test", timestamp: Date()))
        
        // 2. Mock Response
        mockService.mockResponse = TestHelpers.unsafeSafetyResponse
        
        // 3. Assert Failure
        do {
            _ = try await safetyAgent.audit(draft: badDraft, context: menuData, profile: profile)
            XCTFail("❌ Safety Agent failed to block Peanuts!")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Safety Alert"))
        }
    }
    
    // MARK: - Test 2: Decoder Parsing
    
    func testDecoderParsesResponseCorrectly() async throws {
        // 1. Mock Response
        mockService.mockResponse = TestHelpers.safeMenuJSON
        
        // 2. Decode
        let menuData = try await decoderAgent.decode(images: [Data()])
        
        // 3. Assert
        XCTAssertEqual(menuData.sections.count, 1)
        XCTAssertEqual(menuData.sections.first?.name, "Appetizers")
        XCTAssertEqual(menuData.items.first?.originalName, "Spring Rolls")
        XCTAssertEqual(menuData.currency, "USD")
    }
    
    // MARK: - Test 3: Culture Agent Logic (Mocked)
    
    func testCultureAgentReturnsRecommendation() async throws {
        // 1. Mock Response
        mockService.mockResponse = TestHelpers.cultureRecommendationJSON
        
        // 2. Recommend
        let menuData = MenuData(sections: [], currency: "USD", languageDetected: "en", metadata: MenuMetadata(restaurantName: "Test", timestamp: Date()))
        let rec = try await cultureAgent.recommend(from: menuData, profile: UserProfile())
        
        // 3. Assert
        XCTAssertEqual(rec.recommendedItem.originalName, "Spring Rolls")
        XCTAssertEqual(rec.pairings?.first, "Tea")
    }
}
