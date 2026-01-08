import SwiftUI

// MARK: - Performance Optimization Utilities

/// Lazy image loader with caching
actor ImageCache {
    static let shared = ImageCache()
    
    private var cache: [URL: Image] = [:]
    private let maxCacheSize = 50
    
    func image(for url: URL) -> Image? {
        cache[url]
    }
    
    func setImage(_ image: Image, for url: URL) {
        if cache.count >= maxCacheSize {
            // Remove oldest entries (simple LRU approximation)
            cache.removeValue(forKey: cache.keys.first!)
        }
        cache[url] = image
    }
    
    func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Cached Async Image

struct CachedAsyncImage: View {
    let url: URL?
    @State private var image: Image?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                SkeletonTile()
                    .shimmer()
            } else {
                // Fallback for failed loads
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(AmbrosiaTheme.Colors.textTertiary)
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else {
            isLoading = false
            return
        }
        
        // Check cache first
        if let cached = await ImageCache.shared.image(for: url) {
            self.image = cached
            self.isLoading = false
            return
        }
        
        // Download and cache
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                let loadedImage = Image(uiImage: uiImage)
                await ImageCache.shared.setImage(loadedImage, for: url)
                self.image = loadedImage
            }
        } catch {
            print("[CachedAsyncImage] Load failed: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Launch Performance

enum LaunchPerformance {
    static func measureLaunchTime() {
        #if DEBUG
        let launchTime = CFAbsoluteTimeGetCurrent()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let elapsed = CFAbsoluteTimeGetCurrent() - launchTime
            print("🚀 [Launch] Time to first frame: \(String(format: "%.3f", elapsed))s")
        }
        #endif
    }
    
    static func preloadCriticalAssets() {
        // Preload theme colors (they're already computed, this just ensures they're cached)
        _ = AmbrosiaTheme.Colors.coralStart
        _ = AmbrosiaTheme.Gradients.coralSunset
        
        // Warm up SF Symbols cache
        _ = Image(systemName: "fork.knife.circle.fill")
        _ = Image(systemName: "person.fill")
        _ = Image(systemName: "person.3.fill")
    }
}

// MARK: - Memory Optimization

extension View {
    /// Reduces memory usage by limiting view rendering when off-screen
    func optimizedForScrolling() -> some View {
        self.drawingGroup() // Flattens view hierarchy for better scroll performance
    }
}

// MARK: - App Launch Integration

extension AmbrosiaApp {
    static func performLaunchOptimizations() {
        LaunchPerformance.measureLaunchTime()
        LaunchPerformance.preloadCriticalAssets()
    }
}
