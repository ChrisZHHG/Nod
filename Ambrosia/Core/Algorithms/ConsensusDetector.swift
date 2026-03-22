import Foundation

// MARK: - ConsensusDetector
// Utility for detecting and extracting the structured consensus JSON emitted by the Host Moderator.
// Uses typed JSON contract instead of a raw keyword to prevent false positive triggers.

struct ConsensusDetector {

    /// The structured payload that the Host Moderator emits as its final message.
    struct ConsensusSignal: Codable {
        let status: String
        let dishes: [String]
    }

    /// Returns true if the given text contains a valid consensus JSON signal.
    static func isConsensusJSON(_ text: String) -> Bool {
        extractConsensus(from: text) != nil
    }

    /// Attempts to decode the consensus JSON from the text.
    /// Falls back to legacy keyword detection for backwards compatibility.
    static func extractConsensus(from text: String) -> ConsensusSignal? {
        // Primary: extract all {...} substrings and try to decode each as ConsensusSignal.
        for candidate in extractJSONCandidates(from: text) {
            if let data = candidate.data(using: .utf8),
               let signal = try? JSONDecoder().decode(ConsensusSignal.self, from: data),
               signal.status == "consensus",
               !signal.dishes.isEmpty {
                return signal
            }
        }
        // Fallback: legacy keyword detection.
        if text.contains("[CONSENSUS REACHED]") {
            return ConsensusSignal(status: "consensus", dishes: extractKeywordDishes(from: text))
        }
        return nil
    }

    // MARK: - Private Helpers

    /// Extracts all top-level {...} substrings using a single linear scan
    /// (O(n), Unicode-safe via Swift's Character view).
    private static func extractJSONCandidates(from text: String) -> [String] {
        var candidates: [String] = []
        var depth = 0
        var startIndex: String.Index? = nil

        for idx in text.indices {
            switch text[idx] {
            case "{":
                if depth == 0 { startIndex = idx }
                depth += 1
            case "}":
                depth -= 1
                if depth == 0, let start = startIndex {
                    candidates.append(String(text[start...idx]))
                    startIndex = nil
                }
            default:
                break
            }
        }
        return candidates
    }

    /// Extracts dish names listed after "[CONSENSUS REACHED]" for legacy support.
    private static func extractKeywordDishes(from text: String) -> [String] {
        guard let range = text.range(of: "[CONSENSUS REACHED]") else { return [] }
        let remainder = String(text[range.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return remainder
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
