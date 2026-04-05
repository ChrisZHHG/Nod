import SwiftUI

// MARK: - Image Cache (In-Memory)
//
// TODO: Replace AsyncImage with CachedAsyncImage throughout the app once
//       image count / repeat renders justify the optimization.
//       Currently not wired in — all views use the system AsyncImage.

actor ImageCache {
    static let shared = ImageCache()

    private var cache: [URL: Image] = [:]
    private let maxCacheSize = 50

    func image(for url: URL) -> Image? {
        cache[url]
    }

    func setImage(_ image: Image, for url: URL) {
        if cache.count >= maxCacheSize {
            cache.removeValue(forKey: cache.keys.first!)
        }
        cache[url] = image
    }

    func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Skeleton Tile

struct SkeletonTile: View {
    @State private var shimmerOffset: CGFloat = -100

    var body: some View {
        RoundedRectangle(cornerRadius: NodTheme.Radius.lg, style: .continuous)
            .fill(NodTheme.Cinematic.glassDark)
            .overlay(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: NodTheme.Radius.lg, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color.white.opacity(0.08), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: 80)
                        .offset(x: shimmerOffset)
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                shimmerOffset = geo.size.width + 100
                            }
                        }
                }
                .clipped()
            )
            .clipShape(RoundedRectangle(cornerRadius: NodTheme.Radius.lg, style: .continuous))
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geo in
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, Color.white.opacity(0.15), .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: 60)
                    .offset(x: phase * geo.size.width - 60)
                    .onAppear {
                        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    }
            }
            .clipped()
        )
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - Cached Async Image
//
// TODO: Wire this in to replace AsyncImage calls once optimization is needed.

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
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(NodTheme.Cinematic.smokeGray)
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

        if let cached = await ImageCache.shared.image(for: url) {
            self.image = cached
            self.isLoading = false
            return
        }

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
