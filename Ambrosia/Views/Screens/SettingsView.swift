import SwiftUI

// MARK: - Settings / About View

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            NodTheme.Cinematic.deepBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: NodTheme.Spacing.xl) {
                    Color.clear.frame(height: 72)

                    // MARK: - App Identity

                    VStack(alignment: .leading, spacing: NodTheme.Spacing.sm) {
                        HStack(spacing: 14) {
                            // App icon preview
                            RoundedRectangle(cornerRadius: 16)
                                .fill(NodTheme.Cinematic.amber.opacity(0.15))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Text("N")
                                        .font(.system(size: 32, weight: .black, design: .rounded))
                                        .foregroundColor(NodTheme.Cinematic.amber)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nod")
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(NodTheme.Cinematic.pureWhite)

                                Text("The effortless consensus.")
                                    .font(NodTheme.Typography.caption)
                                    .italic()
                                    .foregroundColor(NodTheme.Cinematic.smokeGray)

                                Text("Version \(appVersion) (\(buildNumber))")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(NodTheme.Cinematic.smokeGray.opacity(0.6))
                            }
                        }
                        .padding(NodTheme.Spacing.lg)
                        .glassCard(cornerRadius: NodTheme.Radius.lg)
                    }

                    // MARK: - How It Works

                    sectionHeader("How It Works")

                    VStack(alignment: .leading, spacing: NodTheme.Spacing.md) {
                        infoRow(icon: "camera.fill",        title: "Snap", body: "Photograph any restaurant menu — even multi-page ones.")
                        infoRow(icon: "cpu.fill",           title: "Simmer", body: "AI agents decode dishes, research the restaurant, and match your preferences.")
                        infoRow(icon: "hand.thumbsup.fill", title: "Pick", body: "Get curated recommendations with photos, pairings, and cultural context.")
                    }
                    .padding(NodTheme.Spacing.lg)
                    .glassCard(cornerRadius: NodTheme.Radius.lg)

                    // MARK: - AI & Privacy

                    sectionHeader("AI & Privacy")

                    VStack(alignment: .leading, spacing: NodTheme.Spacing.sm) {
                        Text("Nod uses OpenRouter to route AI requests across best-in-class models. Your menu images are processed in real time and are not stored on any server.")
                            .font(NodTheme.Typography.body)
                            .foregroundColor(NodTheme.Cinematic.smokeGray)
                            .lineSpacing(4)

                        GlassButton(title: "Privacy Policy", icon: "doc.text", variant: .ghost) {
                            openURL(URL(string: "https://chriszhang.github.io/Nod/privacy")!)
                        }
                    }
                    .padding(NodTheme.Spacing.lg)
                    .glassCard(cornerRadius: NodTheme.Radius.lg)

                    // MARK: - Links

                    sectionHeader("Links")

                    VStack(spacing: NodTheme.Spacing.sm) {
                        GlassButton(title: "View on GitHub", icon: "chevron.left.forwardslash.chevron.right", variant: .secondary) {
                            openURL(URL(string: "https://github.com/ChrisZHHG/Nod")!)
                        }
                        GlassButton(title: "Report an Issue", icon: "exclamationmark.bubble", variant: .ghost) {
                            openURL(URL(string: "https://github.com/ChrisZHHG/Nod/issues")!)
                        }
                    }
                }
                .padding(.horizontal, NodTheme.Spacing.xl)
                .padding(.bottom, NodTheme.Spacing.xxl)
            }
            .scrollIndicators(.hidden)
        }
        .floatingNavBar(
            title: "About Nod",
            trailing: .init(icon: "xmark") { dismiss() }
        )
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(NodTheme.Typography.caption)
            .foregroundColor(NodTheme.Cinematic.smokeGray)
            .padding(.horizontal, NodTheme.Spacing.sm)
    }

    @ViewBuilder
    private func infoRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: NodTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(NodTheme.Cinematic.amber)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(NodTheme.Cinematic.pureWhite)
                Text(body)
                    .font(NodTheme.Typography.caption)
                    .foregroundColor(NodTheme.Cinematic.smokeGray)
                    .lineSpacing(2)
            }
        }
    }
}
