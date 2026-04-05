import Foundation

// MARK: - APIKeyService
//
// Fetches API keys from a private remote JSON config at runtime.
// Keys are NEVER hardcoded in the app bundle or committed to git.
//
// Setup:
//   1. Create a private GitHub Gist (github.com/gist) with this JSON structure:
//      {
//        "openrouter": "sk-or-v1-YOUR_KEY_HERE",
//        "google_places": "AIza_YOUR_KEY_HERE"
//      }
//   2. Copy the raw Gist URL (click "Raw" button on the Gist page)
//   3. Paste it into `remoteConfigURL` below.
//
// Security notes:
//   - Keys are cached in-memory only. Never written to disk or UserDefaults.
//   - If fetch fails, all AI features degrade gracefully (no crash).
//   - Rotate keys anytime by updating the Gist — no app update needed.

actor APIKeyService {

    static let shared = APIKeyService()

    // MARK: - ⚠️ Set this to your private Gist raw URL
    private let remoteConfigURL = "https://gist.githubusercontent.com/ChrisZHHG/raw/nod-config.json"

    // MARK: - In-memory cache (never persisted to disk)
    private var openRouterKey: String?
    private var googlePlacesKey: String?
    private var hasFetched = false
    private var isFetching = false
    private var fetchContinuations: [CheckedContinuation<Void, Never>] = []

    private init() {}

    // MARK: - Public API

    /// Returns the OpenRouter API key. Fetches from remote on first call.
    func getOpenRouterKey() async -> String? {
        await ensureLoaded()
        return openRouterKey
    }

    /// Returns the Google Places API key. Fetches from remote on first call.
    func getGooglePlacesKey() async -> String? {
        await ensureLoaded()
        return googlePlacesKey
    }

    // MARK: - Prefetch (call at app launch for faster first request)

    func prefetch() {
        Task { await ensureLoaded() }
    }

    // MARK: - Private

    private func ensureLoaded() async {
        guard !hasFetched else { return }

        // If already fetching, wait for it to finish
        if isFetching {
            await withCheckedContinuation { continuation in
                fetchContinuations.append(continuation)
            }
            return
        }

        isFetching = true
        await fetchConfig()
        hasFetched = true
        isFetching = false

        // Wake up any waiting callers
        let waiting = fetchContinuations
        fetchContinuations.removeAll()
        for c in waiting { c.resume() }
    }

    private func fetchConfig() async {
        guard let url = URL(string: remoteConfigURL) else {
            print("⚠️ [APIKeyService] Invalid remote config URL. AI features will be unavailable.")
            return
        }

        do {
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("⚠️ [APIKeyService] Remote config fetch failed: HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
                print("⚠️ [APIKeyService] Remote config JSON malformed.")
                return
            }

            openRouterKey = json["openrouter"]
            googlePlacesKey = json["google_places"]
            print("✅ [APIKeyService] Keys loaded successfully.")

        } catch {
            print("⚠️ [APIKeyService] Failed to fetch remote config: \(error.localizedDescription)")
        }
    }
}
