import Foundation

/// Defines type-safe routing destinations within the SwiftUI NavigationStack.
enum AppDestination: Hashable {
    case scanner
    case wizard
    case soloResult(SoloRecommendationSet)
    case groupResult(GroupRecommendationSet)
}
