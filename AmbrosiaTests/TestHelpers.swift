import Foundation
@testable import Ambrosia

struct TestHelpers {
    static let safeMenuJSON = """
    {
      "sections": [
        { 
            "name": "Appetizers", 
            "items": [ 
                { "originalName": "Spring Rolls", "description": "Crispy", "price": 5.0, "isSpicy": false, "isVegetarian": true, "containsGluten": true, "containsPeanuts": false, "containsSeafood": false } 
            ] 
        }
      ],
      "currency": "USD",
      "languageDetected": "en",
      "metadata": { "restaurantName": "Golden Dragon", "timestamp": "2024-01-01" }
    }
    """
    
    static let unsafeSafetyResponse = """
    {
        "isSafe": false,
        "violationReason": "Contains Peanuts which violates user allergy."
    }
    """
    
    static let cultureRecommendationJSON = """
    {
      "recommendedItem": { "originalName": "Spring Rolls", "description": "Crispy", "price": 5.0, "isSpicy": false, "isVegetarian": true, "containsGluten": true, "containsPeanuts": false, "containsSeafood": false },
      "translation": {
        "localizedName": "Spring Rolls",
        "culturalContext": "Traditional appetizer.",
        "warnings": []
      },
      "reasoning": "Fits budget.",
      "pairings": ["Tea"]
    }
    """
    
    static let visualizerImageURL = URL(string: "https://example.com/mock_food.jpg")!
}
