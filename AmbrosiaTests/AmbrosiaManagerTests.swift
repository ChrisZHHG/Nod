import XCTest
import Combine
@testable import Ambrosia

@MainActor
final class AmbrosiaManagerTests: XCTestCase {
    
    var manager: AmbrosiaManager!
    var mockService: MockGeminiService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        mockService = MockGeminiService()
        manager = AmbrosiaManager(service: mockService)
        cancellables = []
    }
    
    // MARK: - Test 1: Full State Flow (Happy Path)
    
    func testGenerateRecommendationHappyPath() async {
        print("\n🧪 TEST: Manager Happy Path")
        
        // 1. Setup Mock Behavior
        // The manager calls agents in sequence: Decoder -> Culture -> (Visualizer) -> Safety
        // We need the mock to respond intelligently based on the input prompt (simulated)
        // OR we just return valid JSONs that fit all schemas (lazy mock).
        // Since our agents use specific schemas, we can cheat by making the mock return a "Magic JSON" 
        // that satisfies Decoder, Culture, and Safety parsers if they don't validate strictly against schema type.
        // BUT Decoder expects {sections...} and Culture expects {recommendedItem...}.
        
        // Better approach: Use the `responseHandler` in MockGeminiService
        mockService.responseHandler = { prompt in
            if prompt.contains("Menu Digitizer") { return TestHelpers.safeMenuJSON }
            if prompt.contains("Bely Persona") { return TestHelpers.cultureRecommendationJSON }
            if prompt.contains("Safety Auditor") { return "{\"isSafe\": true}" }
            return "{}"
        }
        mockService.mockImageURL = TestHelpers.visualizerImageURL
        
        // 2. Start Session & Add Image
        manager.startSession()
        if case .scanning = manager.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("State should be scanning")
        }
        
        manager.addImage(Data())
        
        // 3. Trigger Recommendation
        // We need to capture state changes to verify the sequence
        var states: [AppState] = []
        let expectation = XCTestExpectation(description: "Reasoning Completed")
        
        manager.$state
            .dropFirst() // Ignore initial
            .sink { state in
                states.append(state)
                if case .result = state {
                    expectation.fulfill()
                }
                if case .error = state {
                    expectation.fulfill() // Fail faster
                }
            }
            .store(in: &cancellables)
        
        await manager.generateRecommendation()
        
        // 4. Verification
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Check final state
        if case .result(let rec) = manager.state {
            XCTAssertEqual(rec.recommendedItem.originalName, "Spring Rolls")
            XCTAssertEqual(rec.imageURL, TestHelpers.visualizerImageURL) // Visualizer Verification
        } else {
            XCTFail("Final state should be .result")
        }
        
        // Check intermediate states? (Optional, but good for "Coordinator Logic" check)
        // Note: Combine might miss rapid state changes if they happen on MainActor synchronously 
        // without yielding, but `await` calls in manager should allow updates.
        print("Captured States: \(states)")
    }
    
    // MARK: - Test 2: Unhappy Path (Network Error)
    
    func testNetworkErrorHandling() async {
        print("\n🧪 TEST: Network Error")
        
        // 1. Setup Mock Failure
        mockService.mockError = NSError(domain: "Network", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server Down"])
        
        // 2. Trigger
        manager.startSession()
        manager.addImage(Data())
        
        await manager.generateRecommendation()
        
        // 3. Assert
        if case .error(let msg) = manager.state {
            XCTAssertEqual(msg, "Server Down")
        } else {
            XCTFail("State should be .error")
        }
    }
}
