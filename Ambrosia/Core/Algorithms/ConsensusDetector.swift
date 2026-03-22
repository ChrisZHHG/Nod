import Foundation

// MARK: - ConsensusDetector
// Utility for detecting and extracting the structured consensus JSON emitted by the Host Moderator.
// Using a typed JSON contract instead of a raw keyword prevents false positive triggers
// when agents accidentally include "[CONSENSUS REACHED]" as commentary.

struct ConsensusDetector {

    /// The structured payload that the Host Moderator must emit as its ENTIRE final message.
    struct ConsensusSignal: Codable {
        let status: String
        let dishes: [String]
    }

    /// Returns true if the given text is (or contains) a valid consensus JSON signal.
    static func isConsensusJSON(_ text: String) -> Bool {
        extractConsensus(from: text) != nil
    }

    /// Attempts to decode the consensus JSON from the text.
    /// Falls back to legacy keyword detection so old builds stay compatible.
    static func extractConsensus(from text: String) -> ConsensusSignal? {
        // Primary: try to parse JSON directly from text.
        let candidates = extractJSONCandidates(from: text)
        for candidate in candidates {
            if let data = candidate.data(using: .utf8),
               let signal = try? JSONDecoder().decode(ConsensusSignal.self, from: data),
               signal.status == "consensus",
               !signal.dishes.isEmpty {
                return signal
            }
        }
        // Fallback: legacy keyword detection for backwards compatibility.
        if text.contains("[CONSENSUS REACHED]") {
            let dishNames = extractKeywordDishes(from: text)
            return ConsensusSignal(status: "consensus", dishes: dishNames)
        }
        return nil
    }

    // MARK: - Private Helpers

    /// Extracts all {...} substrings from the text for JSON parse attempts.
    private static func extractJSONCandidates(from text: String) -> [String] {
        var candidates: [String] = []
        var depth = 0
        var start: String.Index? = nil
        for (i, ch) in text.enumerated() {
            let idx = text.index(text.startIndex, offsetBy: i)
            if ch == "{" {
                if depth == 0 { start = idx }
                depth += 1
            } else if ch == "}" {
                depth -= 1
                if depth == 0, let s = start {
                    candidates.append(String(text[s...idx]))
                    start = nil
                }
            }
        }
        return candidates
    }

    /// Basic extraction of dish names that follow "[CONSENSUS REACHED]" for legacy support.
    private static func extractKeywordDishes(from text: String) -> [String] {
        guard let range = text.range(of: "[CONSENSUS REACHED]") else { return [] }
        let remainder = String(text[range.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // Split on commas or newlines
        let parts = remainder
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return parts
    }
}
